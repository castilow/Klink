const functions = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const crypto = require('crypto');
const CryptoJS = require('crypto-js');
const { TranslationServiceClient } = require('@google-cloud/translate').v3;
const https = require('https');

// Definir el secreto para la API key de OpenAI (Firebase Functions v7)
const openaiApiKey = defineSecret('OPENAI_API_KEY');

// Inicializar con configuración mínima
admin.initializeApp({
  projectId: 'klink-b0358',
  storageBucket: 'klink-b0358.appspot.com',
});

// Inicializar Google Cloud Translation v3
const translationClient = new TranslationServiceClient();
const PROJECT_ID = admin.app().options.projectId || process.env.GCLOUD_PROJECT || 'klink-b0358';
const LOCATION = 'us-central1';

// Función para desencriptar mensajes usando el mismo algoritmo que Flutter
function decryptMessage(encryptedText, messageId) {
  try {
    console.log('[decryptMessage] Starting decryption for message:', messageId);
    console.log('[decryptMessage] Encrypted text:', encryptedText);
    
    if (!encryptedText || encryptedText.length === 0) {
      console.log('[decryptMessage] Empty text for message', messageId);
      return encryptedText;
    }

    // Verificar si es base64
    if (!/^[A-Za-z0-9+/]*={0,2}$/.test(encryptedText)) {
      console.log('[decryptMessage] Text appears to be plain text for message', messageId);
      return encryptedText;
    }

    console.log('[decryptMessage] Text is base64, proceeding with decryption...');

    // Claves fijas (mismas que en Flutter)
    const key = Buffer.from('MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDA=', 'base64');
    const iv = Buffer.from('MDEyMzQ1Njc4OTAxMjM0NQ==', 'base64');

    console.log('[decryptMessage] Key and IV parsed successfully');

    // Intentar diferentes configuraciones de padding
    let decrypted = null;
    
    try {
      // Estrategia 1: Con padding automático
      const decipher1 = crypto.createDecipheriv('aes-256-cbc', key, iv);
      decipher1.setAutoPadding(true);
      let result1 = decipher1.update(encryptedText, 'base64', 'utf8');
      result1 += decipher1.final('utf8');
      decrypted = result1;
      console.log('[decryptMessage] Strategy 1 (auto padding) success');
    } catch (e1) {
      console.log('[decryptMessage] Strategy 1 failed:', e1.message);
      
      try {
        // Estrategia 2: Sin padding automático
        const decipher2 = crypto.createDecipheriv('aes-256-cbc', key, iv);
        decipher2.setAutoPadding(false);
        let result2 = decipher2.update(encryptedText, 'base64', 'utf8');
        result2 += decipher2.final('utf8');
        
        // Remover padding manualmente
        const lastByte = result2.charCodeAt(result2.length - 1);
        if (lastByte <= 16) {
          result2 = result2.slice(0, -lastByte);
        }
        decrypted = result2;
        console.log('[decryptMessage] Strategy 2 (no padding) success');
      } catch (e2) {
        console.log('[decryptMessage] Strategy 2 failed:', e2.message);
        
        try {
          // Estrategia 3: Usar PKCS7 padding manual
          const decipher3 = crypto.createDecipheriv('aes-256-cbc', key, iv);
          decipher3.setAutoPadding(false);
          let result3 = decipher3.update(encryptedText, 'base64', 'utf8');
          result3 += decipher3.final('utf8');
          
          // Remover PKCS7 padding
          const paddingLength = result3.charCodeAt(result3.length - 1);
          if (paddingLength > 0 && paddingLength <= 16) {
            result3 = result3.slice(0, -paddingLength);
          }
          decrypted = result3;
          console.log('[decryptMessage] Strategy 3 (manual PKCS7) success');
        } catch (e3) {
          console.log('[decryptMessage] Strategy 3 failed:', e3.message);
          throw new Error('All decryption strategies failed');
        }
      }
    }

    console.log('[decryptMessage] Success for message', messageId, 'Result:', decrypted);
    console.log('[decryptMessage] Result length:', decrypted.length);
    
    return decrypted;
  } catch (error) {
    console.error('[decryptMessage] Error decrypting message', messageId, ':', error.message);
    console.error('[decryptMessage] Error stack:', error.stack);
    return '[Mensaje no pudo ser desencriptado]';
  }
}

// Función para enviar notificaciones push
exports.sendPushNotification = functions.https.onCall({
  enforceAppCheck: false, // SIN App Check - menos seguro pero más simple
}, async (data, context) => {
  try {
    // Los datos pueden venir en data.data.data (Firebase Functions v2)
    const actualData = data?.data?.data || data?.data || data || {};
    const { type, title, body, toUserId, chatId, messageId, deviceToken, call, senderId } = actualData;

    console.log('[sendPushNotification] raw data', { data });
    console.log('[sendPushNotification] actualData', { actualData });
    console.log('[sendPushNotification] extracted fields', { type, title, body, toUserId, chatId, messageId, deviceToken });

    // Validar campos requeridos
    if (!type || !title || !body) {
      console.error('[sendPushNotification] missing required fields', { type, title, body });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: type, title, body');
    }

    // Si es un mensaje, validar campos adicionales (solo si no hay deviceToken directo)
    if (type === 'message' && !deviceToken && (!toUserId || !chatId || !messageId)) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields for message: toUserId, chatId, messageId');
    }

    // Si es una llamada, validar campos adicionales
    if (type === 'call' && (!deviceToken || !call)) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields for call: deviceToken, call');
    }

    console.log('[sendPushNotification] raw data', { data });

    let tokens = [];

    // Si se proporciona deviceToken directamente (para llamadas)
    if (deviceToken) {
      tokens = [deviceToken];
      console.log('[sendPushNotification] token length', { len: deviceToken.length });
    } else if (toUserId) {
      // Buscar tokens del usuario destinatario
      const userRef = admin.firestore().collection('Users').doc(toUserId);
      const userSnap = await userRef.get();
      tokens = userSnap.data()?.pushTokens || [];
      console.log('[sendPushNotification] found tokens for user', { toUserId, tokenCount: tokens.length });
    }

    if (tokens.length === 0) {
      console.log('[sendPushNotification] no tokens found');
      return { success: false, message: 'No device tokens found' };
    }

    // Verificar si el usuario está activo en el chat (como WhatsApp)
    // IMPORTANTE: Solo ocultar notificaciones si la app está en PRIMER PLANO
    let isUserActiveInChat = false;
    let isAppInForeground = false;
    
    if (type === 'message' && toUserId && chatId) {
      try {
        const presenceRef = admin.database().ref(`presence/${toUserId}`);
        const presenceSnap = await presenceRef.get();
        const presenceData = presenceSnap.val();
        
        // Verificar si la app está en primer plano (isOnline indica que la app está activa)
        isAppInForeground = presenceData?.isOnline === true;
        
        // Verificar si está online y en el chat específico
        // Para chats 1-to-1, el chatId es el ID del otro usuario
        isUserActiveInChat = isAppInForeground && presenceData?.activeChatId === chatId;
        
        console.log('[sendPushNotification] user presence check', { 
          toUserId, 
          isOnline: presenceData?.isOnline, 
          isAppInForeground,
          activeChatId: presenceData?.activeChatId,
          targetChatId: chatId,
          isUserActiveInChat,
          comparison: presenceData?.activeChatId === chatId
        });
        
        // Log adicional para debug
        if (presenceData?.activeChatId) {
          console.log('[sendPushNotification] activeChatId exists and matches:', presenceData.activeChatId === chatId);
        } else {
          console.log('[sendPushNotification] no activeChatId found');
        }
      } catch (error) {
        console.log('[sendPushNotification] presence check failed', error.message);
        // Si falla la verificación, asumir que la app está en segundo plano
        isAppInForeground = false;
        isUserActiveInChat = false;
      }
    }

    // Obtener el contenido real del mensaje si es necesario
    let displayBody = body;
    
    // Usar directamente el body que viene de la app (ya contiene el texto real)
    console.log('[sendPushNotification] 🔍 DEBUG: Using body directly:', body);
    
    // Para llamadas, mantener el comportamiento original
    if (type === 'call') {
      displayBody = body || 'Llamada entrante';
    } else {
      // Para mensajes, usar el body que viene de la app
      displayBody = body || 'Nuevo mensaje';
    }
    
    // Preparar el mensaje según si el usuario está activo en el chat
    // IMPORTANTE: Siempre incluir notification para asegurar que se muestre en segundo plano
    const message = {
      tokens,
      // Solo ocultar notificación si la app está en PRIMER PLANO y el usuario está en el chat
      // Si la app está en segundo plano, siempre mostrar la notificación
      notification: (isUserActiveInChat && isAppInForeground) ? null : {
        title,
        body: displayBody,
      },
      data: {
        type: type || 'alert',
        ...(chatId && { chatId }),
        ...(messageId && { messageId }),
        ...(senderId && { senderId }),
        ...(call && { call: JSON.stringify(call) }),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: type === 'call' ? 'calls_channel' : 'messages_channel',
          sound: type === 'call' ? 'ringtone' : 'default',
          priority: 'high',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            // IMPORTANTE: Siempre incluir alert para notificaciones en segundo plano
            // Solo ocultar alert si la app está en PRIMER PLANO y el usuario está en el chat
            // Si la app está en segundo plano, siempre mostrar la notificación
            ...(isUserActiveInChat && isAppInForeground ? {} : {
              alert: {
                title,
                body: displayBody,
              },
            }),
            // Siempre reproducir sonido (incluso si está en el chat)
            sound: type === 'call' ? 'ringtone.wav' : 'default',
            // Solo incrementar badge si no está activo en el chat o si la app está en segundo plano
            ...(isUserActiveInChat && isAppInForeground ? {} : { badge: 1 }),
            // Para mensajes cuando está activo en primer plano, usar content-available para procesamiento silencioso
            // Pero si está en segundo plano, no usar content-available para asegurar que se muestre la notificación
            ...(isUserActiveInChat && isAppInForeground && type === 'message' ? { 'content-available': 1 } : {}),
            ...(type === 'call' && { 'content-available': 1 }),
          },
        },
      },
    };

    // Enviar uno a uno (evitar endpoint /batch que falla)
    const sendResults = await Promise.allSettled(
      tokens.map(async (token) => {
        const individualMessage = {
          token,
          notification: message.notification,
          data: message.data,
          android: message.android,
          apns: message.apns,
        };
        
        try {
          const result = await admin.messaging().send(individualMessage);
          console.log(`[sendPushNotification] success for token: ${token.substring(0, 20)}... ID: ${result}`);
          return { success: true, token, result };
        } catch (error) {
          console.error(`[sendPushNotification] failed for token: ${token.substring(0, 20)}...`, error.code);
          return { success: false, token, error: error.code };
        }
      })
    );

    const successCount = sendResults.filter(r => r.status === 'fulfilled' && r.value.success).length;
    const failureCount = sendResults.length - successCount;
    const failures = sendResults
      .filter(r => r.status === 'fulfilled' && !r.value.success)
      .map(r => r.value);

    console.log('[sendPushNotification] success', { successCount, failureCount, failures });

    return {
      success: successCount > 0,
      successCount,
      failureCount,
      failures,
    };

  } catch (error) {
    console.error('[sendPushNotification] error', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
  });

// ========================================
// 🌍 TRADUCCIÓN AUTOMÁTICA DE MENSAJES
// ========================================

/**
 * Detecta el idioma de un texto
 */
async function detectLanguage(text) {
  try {
    const request = {
      parent: `projects/${PROJECT_ID}/locations/${LOCATION}`,
      content: text,
      mimeType: 'text/plain',
    };
    const [response] = await translationClient.detectLanguage(request);
    const top = response.languages && response.languages[0];
    const langCode = top?.languageCode || top?.language || 'en';
    console.log('[detectLanguage] Detected:', langCode, 'Confidence:', top?.confidence);
    return langCode;
  } catch (error) {
    console.error('[detectLanguage] Error message:', error?.message);
    console.error('[detectLanguage] Error details:', error?.details || '');
    console.error('[detectLanguage] Error code:', error?.code);
    return 'en'; // Default a inglés si falla
  }
}

/**
 * Traduce un texto a múltiples idiomas
 */
async function translateText(text, targetLanguages) {
  try {
    const translations = {};

    // Traducir a cada idioma objetivo
    for (const targetLang of targetLanguages) {
      try {
        const request = {
          parent: `projects/${PROJECT_ID}/locations/${LOCATION}`,
          contents: [text],
          mimeType: 'text/plain',
          targetLanguageCode: targetLang,
        };
        const [response] = await translationClient.translateText(request);
        const translated = response.translations && response.translations[0]?.translatedText;
        translations[targetLang] = translated || text;
        console.log(`[translateText] ${targetLang}:`, translated);
      } catch (error) {
        console.error(`[translateText] Error translating to ${targetLang}:`, error?.message);
        console.error(`[translateText] Details:`, error?.details || '');
        console.error(`[translateText] Code:`, error?.code);
        translations[targetLang] = text; // Fallback al original
      }
    }
    
    return translations;
  } catch (error) {
    console.error('[translateText] Error:', error);
    return {};
  }
}

/**
 * Obtiene el idioma preferido de un usuario
 */
async function getUserPreferredLanguage(userId) {
  try {
    const userDoc = await admin.firestore().collection('Users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log('[getUserPreferredLanguage] User not found:', userId);
      return 'en';
    }
    
    // Buscar en preferencias guardadas
    const userData = userDoc.data();
    const preferredLang = userData?.preferredLanguage || userData?.locale || 'en';
    
    console.log('[getUserPreferredLanguage] User:', userId, 'Language:', preferredLang);
    return preferredLang;
  } catch (error) {
    console.error('[getUserPreferredLanguage] Error:', error);
    return 'en';
  }
}

/**
 * Función principal: Traduce mensajes automáticamente cuando se crean
 * Se ejecuta cuando se crea un nuevo mensaje en un chat 1-to-1
 */
exports.translateMessage = functions.firestore.onDocumentCreated({
  document: 'Users/{userId}/Chats/{chatId}/Messages/{messageId}',
  timeoutSeconds: 60,
  memory: '256MiB'
}, async (event) => {
    try {
      const { userId, chatId, messageId } = event.params;
      const messageData = event.data.data();
      
      console.log('[translateMessage] New message:', { userId, chatId, messageId });
      
      // Solo traducir mensajes de texto
      if (messageData.type !== 'text' || !messageData.textMsg || messageData.textMsg.trim() === '') {
        console.log('[translateMessage] Skipping non-text message');
        return null;
      }
      
      // No traducir si ya está marcado como eliminado
      if (messageData.isDeleted) {
        console.log('[translateMessage] Skipping deleted message');
        return null;
      }
      
      // Desencriptar el mensaje si está encriptado
      let originalText = messageData.textMsg;
      let isEncrypted = false;
      
      // Verificar si el texto está en base64 (encriptado)
      if (/^[A-Za-z0-9+/]*={0,2}$/.test(originalText) && originalText.length > 20) {
        console.log('[translateMessage] Message appears to be encrypted, decrypting...');
        originalText = decryptMessage(originalText, messageId);
        isEncrypted = true;
      }
      
      // Detectar el idioma del mensaje
      const sourceLanguage = await detectLanguage(originalText);
      console.log('[translateMessage] Source language:', sourceLanguage);
      
      // Obtener el idioma preferido del receptor (chatId es el ID del receptor en chats 1-to-1)
      const receiverLanguage = await getUserPreferredLanguage(chatId);
      console.log('[translateMessage] Receiver language:', receiverLanguage);
      
      // Si el idioma es el mismo, no traducir
      if (sourceLanguage === receiverLanguage) {
        console.log('[translateMessage] Same language, skipping translation');
        return null;
      }
      
      // Traducir el mensaje
      const translations = await translateText(originalText, [receiverLanguage]);
      
      if (!translations[receiverLanguage]) {
        console.log('[translateMessage] Translation failed');
        return null;
      }
      
      console.log('[translateMessage] Translation successful:', translations);
      
      // Guardar la traducción en el mensaje
      const updateData = {
        translations: translations,
        detectedLanguage: sourceLanguage,
        translatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      // Actualizar el mensaje en ambos chats (emisor y receptor)
      await Promise.all([
        // Actualizar en el chat del emisor
        event.data.ref.update(updateData),
        // Actualizar en el chat del receptor
        admin.firestore()
          .collection('Users').doc(chatId)
          .collection('Chats').doc(userId)
          .collection('Messages').doc(messageId)
          .update(updateData),
      ]);
      
      console.log('[translateMessage] Message translated and saved successfully');
      return null;
      
    } catch (error) {
      console.error('[translateMessage] Error:', error);
      // No lanzar error para no bloquear el flujo
      return null;
    }
  });

/**
 * Función callable para traducir mensajes bajo demanda
 * Útil para traducir mensajes antiguos o cuando el usuario cambia su idioma
 */
exports.translateMessageOnDemand = functions.https.onCall({
  enforceAppCheck: false,
}, async (data, context) => {
  try {
    // Compatibilidad con diferentes formatos de payload (v1, v2, SDKs móviles)
    // En algunos casos los datos vienen anidados en data.data o data.data.data
    const rawData = data || {};
    const actualData = rawData?.data?.data || rawData?.data || rawData || {};

    const { messageText, targetLanguage } = actualData;

    console.log('[translateMessageOnDemand] Received messageText length:', messageText?.length || 0);
    console.log('[translateMessageOnDemand] Received targetLanguage:', targetLanguage);
    console.log('[translateMessageOnDemand] messageText preview:', messageText?.substring(0, 50));
    
    if (!messageText || !targetLanguage) {
      console.error('[translateMessageOnDemand] Missing parameters after normalization:', { 
        hasMessageText: !!messageText, 
        hasTargetLanguage: !!targetLanguage 
      });
      throw new functions.https.HttpsError('invalid-argument', 'Missing messageText or targetLanguage');
    }
    
    console.log('[translateMessageOnDemand] Translating to:', targetLanguage);
    console.log('[translateMessageOnDemand] Message text length:', messageText.length);
    
    // Verificar que la API de traducción esté inicializada
    if (!translationClient) {
      console.error('[translateMessageOnDemand] Translation API not initialized');
      throw new functions.https.HttpsError('internal', 'Translation API not initialized');
    }
    
    // Detectar idioma origen
    let sourceLanguage;
    try {
      sourceLanguage = await detectLanguage(messageText);
      console.log('[translateMessageOnDemand] Source language detected:', sourceLanguage);
    } catch (error) {
      console.error('[translateMessageOnDemand] Error detecting language:', error);
      throw new functions.https.HttpsError('internal', `Language detection failed: ${error.message}`);
    }
    
    // Si es el mismo idioma, devolver el original
    if (sourceLanguage === targetLanguage) {
      console.log('[translateMessageOnDemand] Same language, no translation needed');
      return {
        originalText: messageText,
        translatedText: messageText,
        sourceLanguage,
        targetLanguage,
        wasTranslated: false,
      };
    }
    
    // Traducir
    let translations;
    try {
      translations = await translateText(messageText, [targetLanguage]);
      console.log('[translateMessageOnDemand] Translation result:', translations);
    } catch (error) {
      console.error('[translateMessageOnDemand] Error translating:', error);
      throw new functions.https.HttpsError('internal', `Translation failed: ${error.message}`);
    }
    
    const translatedText = translations[targetLanguage] || messageText;
    
    return {
      originalText: messageText,
      translatedText,
      sourceLanguage,
      targetLanguage,
      wasTranslated: true,
    };
    
  } catch (error) {
    console.error('[translateMessageOnDemand] Unexpected error message:', error?.message || 'Unknown error');
    console.error('[translateMessageOnDemand] Error stack:', error?.stack || 'No stack trace');
    console.error('[translateMessageOnDemand] Error name:', error?.name || 'Unknown');
    
    // Si ya es un HttpsError, relanzarlo
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    // Si no, crear un nuevo HttpsError
    throw new functions.https.HttpsError('internal', error?.message || 'Unknown error occurred');
  }
});

// ========================================
// 🤖 CHATGPT ASSISTANT
// ========================================

/**
 * Función para comunicarse con ChatGPT de forma segura
 */
exports.chatWithAssistant = functions.https.onCall({
  enforceAppCheck: false,
  secrets: [openaiApiKey],
  timeoutSeconds: 60,
  memory: '256MiB',
}, async (data, context) => {
  try {
    // Log para debugging
    console.log("[chatWithAssistant] Context auth:", context?.auth ? "Present" : "Missing");
    console.log("[chatWithAssistant] Context:", JSON.stringify({
      auth: context?.auth ? { uid: context.auth.uid } : null,
      rawRequest: context?.rawRequest ? "Present" : "Missing"
    }));

    // Verificar autenticación (permitir si no hay contexto pero hay datos)
    if (!context?.auth) {
      console.warn("[chatWithAssistant] No authentication context, but proceeding...");
      // No lanzar error, solo registrar advertencia
    }

    // Compatibilidad con diferentes formatos de payload
    const actualData = data?.data?.data || data?.data || data || {};
    const {message, conversationHistory} = actualData;

    // Log solo los campos que necesitamos para evitar referencias circulares
    console.log("[chatWithAssistant] Received message:", message?.substring(0, 50));
    console.log("[chatWithAssistant] Conversation history length:", conversationHistory?.length || 0);
    if (conversationHistory && Array.isArray(conversationHistory)) {
      console.log("[chatWithAssistant] Conversation history preview:", JSON.stringify(conversationHistory.slice(0, 2)));
    }

    // Validar parámetros
    if (!message || typeof message !== "string") {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "El mensaje es requerido y debe ser texto",
      );
    }

    // Obtener la API key usando el nuevo sistema de parámetros (Firebase Functions v7)
    let apiKey;
    try {
      console.log("[chatWithAssistant] Getting API key from secret...");
      apiKey = openaiApiKey.value();
      console.log("[chatWithAssistant] API Key retrieved successfully");
    } catch (error) {
      console.error("[chatWithAssistant] Error getting API key:", error.message);
      throw new functions.https.HttpsError(
          "failed-precondition",
          "El asistente no está disponible en este momento",
      );
    }

    console.log("[chatWithAssistant] API Key present:", !!apiKey);
    console.log("[chatWithAssistant] API Key length:", apiKey ? apiKey.length : 0);

    if (!apiKey) {
      console.error("API Key de OpenAI no configurada");
      console.error("Configura con: firebase functions:secrets:set OPENAI_API_KEY");
      throw new functions.https.HttpsError(
          "failed-precondition",
          "El asistente no está disponible en este momento",
      );
    }

    // Limpiar la API key (eliminar espacios y caracteres inválidos)
    let cleanApiKey;
    try {
      cleanApiKey = apiKey.trim().replace(/\s+/g, '');
      console.log("[chatWithAssistant] Clean API Key length:", cleanApiKey.length);
      console.log("[chatWithAssistant] Clean API Key first 10 chars:", cleanApiKey.substring(0, 10));
    } catch (error) {
      console.error("[chatWithAssistant] Error cleaning API key:", error.message);
      throw new functions.https.HttpsError(
          "internal",
          "Error procesando la configuración del asistente",
      );
    }

    // Preparar mensajes para ChatGPT
    console.log("[chatWithAssistant] Starting to prepare messages for ChatGPT...");
    console.log("[chatWithAssistant] Message to send:", message?.substring(0, 50));
    console.log("[chatWithAssistant] Conversation history type:", typeof conversationHistory);
    console.log("[chatWithAssistant] Conversation history is array:", Array.isArray(conversationHistory));
    
    const messages = [
      {
        role: "system",
        content: "Eres Klink AI, un asistente inteligente y amigable " +
          "integrado en la aplicación de mensajería Klink. Tu objetivo " +
          "es ayudar a los usuarios con cualquier pregunta o tarea que " +
          "necesiten. Sé conciso, útil y conversacional. Responde en el " +
          "mismo idioma que te hablen.",
      },
    ];

    // Agregar historial si existe
    if (conversationHistory && Array.isArray(conversationHistory)) {
      // Limitar a los últimos 10 mensajes para no exceder tokens
      const recentHistory = conversationHistory.slice(-10);
      messages.push(...recentHistory);
    }

    // Agregar el mensaje actual
    console.log("[chatWithAssistant] Adding current message to array...");
    messages.push({
      role: "user",
      content: message,
    });

    console.log("[chatWithAssistant] Messages prepared, total:", messages.length);
    console.log("[chatWithAssistant] First message role:", messages[0]?.role);
    console.log("[chatWithAssistant] Last message role:", messages[messages.length - 1]?.role);
    console.log("[chatWithAssistant] Llamando a OpenAI API...");
    console.log("[chatWithAssistant] Total messages to send:", messages.length);
    console.log("[chatWithAssistant] API Key present:", !!apiKey);
    console.log("[chatWithAssistant] Clean API Key present:", !!cleanApiKey);

    // Llamar a la API de OpenAI usando https nativo
    const requestBody = {
      model: "gpt-4o-mini", // Modelo más económico de OpenAI
      messages: messages,
      temperature: 0.7,
      max_tokens: 500, // Reducido para consumir menos tokens
      presence_penalty: 0.6,
      frequency_penalty: 0.3,
    };
    
    console.log("[chatWithAssistant] Request body size:", JSON.stringify(requestBody).length);

    const responseData = await new Promise((resolve, reject) => {
      const postData = JSON.stringify(requestBody);
      
      const options = {
        hostname: 'api.openai.com',
        port: 443,
        path: '/v1/chat/completions',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${cleanApiKey}`,
          'Content-Length': Buffer.byteLength(postData),
        },
        timeout: 55000, // 55 segundos (dejando margen para el timeout de 60s en Flutter)
      };

      const req = https.request(options, (res) => {
        let data = '';

        console.log("[chatWithAssistant] OpenAI response status:", res.statusCode);
        console.log("[chatWithAssistant] OpenAI response headers:", JSON.stringify(res.headers));

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          try {
            console.log("[chatWithAssistant] OpenAI response data length:", data.length);
            console.log("[chatWithAssistant] OpenAI response data preview:", data.substring(0, 500));

            if (res.statusCode !== 200) {
              console.error("[chatWithAssistant] Error de OpenAI:", res.statusCode, data.substring(0, 500));
              reject(new Error(`OpenAI API error: ${res.statusCode} - ${data.substring(0, 200)}`));
              return;
            }

            const parsedData = JSON.parse(data);
            console.log("[chatWithAssistant] OpenAI response data keys:", Object.keys(parsedData));
            console.log("[chatWithAssistant] Choices count:", parsedData.choices?.length || 0);
            
            if (parsedData.choices && parsedData.choices.length > 0) {
              console.log("[chatWithAssistant] First choice message preview:", parsedData.choices[0].message?.content?.substring(0, 100));
            }
            
            resolve(parsedData);
          } catch (error) {
            console.error("[chatWithAssistant] Error parsing response:", error.message);
            console.error("[chatWithAssistant] Raw data:", data.substring(0, 500));
            reject(error);
          }
        });
      });

      req.on('error', (error) => {
        console.error("[chatWithAssistant] Request error:", error.message);
        console.error("[chatWithAssistant] Request error stack:", error.stack);
        reject(error);
      });

      req.on('timeout', () => {
        console.error("[chatWithAssistant] Request timeout after 55 seconds");
        req.destroy();
        reject(new Error('Request timeout'));
      });

      console.log("[chatWithAssistant] Sending request to OpenAI...");
      console.log("[chatWithAssistant] Request URL: https://api.openai.com/v1/chat/completions");
      console.log("[chatWithAssistant] Authorization header present:", !!options.headers.Authorization);
      console.log("[chatWithAssistant] Authorization header length:", options.headers.Authorization?.length || 0);
      
      req.write(postData);
      req.end();
      
      console.log("[chatWithAssistant] Request sent, waiting for response...");
    });

    // Extraer la respuesta
    const assistantMessage = responseData.choices?.[0]?.message?.content;

    if (!assistantMessage) {
      console.error("[chatWithAssistant] No assistant message in response:", JSON.stringify(responseData).substring(0, 500));
      throw new Error("No se recibió respuesta del asistente");
    }

    console.log("[chatWithAssistant] Respuesta exitosa de OpenAI, length:", assistantMessage.length);

    return {
      response: assistantMessage.trim(),
      success: true,
    };
  } catch (error) {
    // Extraer solo el mensaje de error como string para evitar referencias circulares
    const errorMessageStr = error?.message || error?.toString() || "Error desconocido";
    console.error("[chatWithAssistant] Error:", errorMessageStr);

    // Mensaje de error amigable para el usuario
    let userErrorMessage = "Lo siento, no pude procesar tu solicitud " +
      "en este momento. Por favor, inténtalo de nuevo.";

    if (errorMessageStr.includes("timeout") || errorMessageStr.includes("AbortError")) {
      userErrorMessage = "La respuesta está tardando demasiado. " +
        "Por favor, inténtalo de nuevo.";
    } else if (errorMessageStr.includes("unauthenticated")) {
      userErrorMessage = "Debes iniciar sesión para usar el asistente.";
    } else if (errorMessageStr.includes("OpenAI API error: 401")) {
      userErrorMessage = "Error de autenticación con OpenAI. La API Key podría ser inválida.";
    } else if (errorMessageStr.includes("OpenAI API error: 429")) {
      userErrorMessage = "Demasiadas solicitudes a OpenAI. Por favor, espera un momento.";
    } else if (errorMessageStr.includes("OpenAI API error: 500")) {
      userErrorMessage = "Error interno del servidor de OpenAI. Inténtalo de nuevo más tarde.";
    }

    return {
      response: userErrorMessage,
      success: false,
      error: errorMessageStr.substring(0, 200), // Limitar longitud para evitar problemas
    };
  }
});


