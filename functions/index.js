const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const CryptoJS = require('crypto-js');

// Inicializar con configuración mínima
admin.initializeApp({
  projectId: 'arious-4a07f',
  storageBucket: 'arious-4a07f.appspot.com',
});

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
    let isUserActiveInChat = false;
    if (type === 'message' && toUserId && chatId) {
      try {
        const presenceRef = admin.database().ref(`presence/${toUserId}`);
        const presenceSnap = await presenceRef.get();
        const presenceData = presenceSnap.val();
        
        // Verificar si está online y en el chat específico
        // Para chats 1-to-1, el chatId es el ID del otro usuario
        isUserActiveInChat = presenceData?.isOnline && presenceData?.activeChatId === chatId;
        
        console.log('[sendPushNotification] user presence check', { 
          toUserId, 
          isOnline: presenceData?.isOnline, 
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
    const message = {
      tokens,
      // Si está activo en el chat, no mostrar notificación banner (solo sonido)
      notification: isUserActiveInChat ? null : {
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
            // Si está activo en el chat, no mostrar alert (solo sonido)
            ...(isUserActiveInChat ? {} : {
              alert: {
                title,
                body: displayBody,
              },
            }),
            // Siempre reproducir sonido (incluso si está en el chat)
            sound: type === 'call' ? 'ringtone.wav' : 'default',
            // Solo incrementar badge si no está activo en el chat
            ...(isUserActiveInChat ? {} : { badge: 1 }),
            // Para mensajes cuando está activo, usar content-available para procesamiento silencioso
            ...(isUserActiveInChat && type === 'message' ? { 'content-available': 1 } : {}),
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


