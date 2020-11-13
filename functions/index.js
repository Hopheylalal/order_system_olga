const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { DataSnapshot } = require('firebase-functions/lib/providers/database');
//const nodemailer = require('nodemailer');


admin.initializeApp(functions.config().firebase);

var msgData;
var respondMsgData;
var newUserData;



exports.msgTrigger = functions.firestore.document(
    'messages/{messagesId}/chat/{messages}'
).onCreate((snapshot, context) => {
    msgData = snapshot.data();
    var recipient = msgData['to'];
    var content = msgData['content'];
    var from = msgData['sender'];
    var nameAdmin = msgData['nameAdmin'];


    return admin.firestore().doc('masters/' + recipient).get().then(userDoc => {
        const registrationTokens = userDoc.get('token')

        var payload = {
            notification: {
                title: nameAdmin,
                body:  content.length > 4 ? content.substr(0, 4) === 'http' ? 'Фото' : content : content,
                sound: "default",
                msg: 'msg',

            },
             data: {
               title: nameAdmin,
               content: content.length > 4 ? content.substr(0, 4) === 'http' ? 'Фото' : content : content,
               clickAction: 'FLUTTER_NOTIFICATION_CLICK',
               type: 'msg',
          }
        }
        return admin.messaging().sendToDevice(registrationTokens, payload).then((response) => {
            console.log('OK is OK message')
            console.log(content.length)
//            const stillRegisteredTokens = registrationTokens
//                        response.results.forEach((result, index) => {
//                            const error = result.error
//                            if (error) {
//                                const failedRegistrationToken = registrationTokens[index]
//                                console.error('blah', failedRegistrationToken, error)
//                                if (error.code === 'messaging/invalid-registration-token'
//                                    || error.code === 'messaging/registration-token-not-registered') {
//                                    const failedIndex = stillRegisteredTokens.indexOf(failedRegistrationToken)
//                                    if (failedIndex > -1) {
//                                        stillRegisteredTokens.splice(failedIndex, 1)
//                                    }
//                                }
//                            }
//                        })
//
//                        return admin.firestore().doc('masters/' + recipient).update({
//                            token: stillRegisteredTokens
//                        })
        }).catch((err) => { console.log(err + 'ERROR FROM ADMIN') });
    })
})

//-----------------------------------------------------------------------------------------
exports.commentTrigger = functions.firestore.document(
    'comments/{commentId}'
).onCreate((snapshot, context) => {
    commentData = snapshot.data();
    var recipient = commentData['masterId'];
    var content = commentData['content'];
    var from = commentData['ownerId'];
    var ownerName = commentData['ownerName'];


    return admin.firestore().doc('masters/' + recipient).get().then(userDoc => {
        const registrationTokens = userDoc.get('token')

        var payload = {
            notification: {
                title: 'Новый отзыв от',
                body: ownerName,
                sound: "default"

            },
             data: {
               title: 'Новый отзыв от',
               content: ownerName,
               clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          }
        }
        return admin.messaging().sendToDevice(registrationTokens, payload).then((response) => {
            console.log('OK is OK comment')
//            const stillRegisteredTokens = registrationTokens
//                        response.results.forEach((result, index) => {
//                            const error = result.error
//                            if (error) {
//                                const failedRegistrationToken = registrationTokens[index]
//                                console.error('blah', failedRegistrationToken, error)
//                                if (error.code === 'messaging/invalid-registration-token'
//                                    || error.code === 'messaging/registration-token-not-registered') {
//                                    const failedIndex = stillRegisteredTokens.indexOf(failedRegistrationToken)
//                                    if (failedIndex > -1) {
//                                        stillRegisteredTokens.splice(failedIndex, 1)
//                                    }
//                                }
//                            }
//                        })
//
//                        return admin.firestore().doc('masters/' + recipient).update({
//                            token: stillRegisteredTokens
//                        })
        }).catch((err) => { console.log(err + 'ERROR FROM ADMIN COMMENT TRIGGER') });
    })
})

//------------------------------------------------------------------------------------------




exports.newOrderToMasterTrigger = functions.firestore.document(
    'orders/{orderId}'
).onCreate((snapshot, context) => {
    orderData = snapshot.data();
    var recipient = orderData['orderOwnerUid'];
    var masterId = orderData['toMaster'];
    var from = orderData['name'];


    return admin.firestore().doc('masters/' + masterId).get().then(userDoc => {
        const registrationTokens = userDoc.get('token')

        var payload = {
            notification: {
                title: 'Новое задание от:',
                body: from,
                sound: "default"

            },
             data: {
               title: 'Новое задание от:',
               content: from,
               clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          }
        }
        return admin.messaging().sendToDevice(registrationTokens, payload).then((response) => {
            console.log('OK is OK comment')
//            const stillRegisteredTokens = registrationTokens
//                        response.results.forEach((result, index) => {
//                            const error = result.error
//                            if (error) {
//                                const failedRegistrationToken = registrationTokens[index]
//                                console.error('blah', failedRegistrationToken, error)
//                                if (error.code === 'messaging/invalid-registration-token'
//                                    || error.code === 'messaging/registration-token-not-registered') {
//                                    const failedIndex = stillRegisteredTokens.indexOf(failedRegistrationToken)
//                                    if (failedIndex > -1) {
//                                        stillRegisteredTokens.splice(failedIndex, 1)
//                                    }
//                                }
//                            }
//                        })
//
//                        return admin.firestore().doc('masters/' + recipient).update({
//                            token: stillRegisteredTokens
//                        })
        }).catch((err) => { console.log(err + 'ERROR FROM ADMIN RESPOND TRIGGER') });
    })
})

//exports.sendEmail = functions.firestore.document(
//    'masters/{masterId}'
//).onCreate((snapshot, context) => {
//    newUserData = snapshot.data();
//    var fromWeb = newUserData['fromWeb'];
//    var userMail = newUserData['email'];
//    var pass = newUserData['pass'];
//    if(fromWeb === true){
//        var transporter = nodemailer.createTransport({
//            host: 'smtp.gmail.com',
//            port: 587,
//            secure: false,
//            auth: {
//                user: 'order.system.app2@gmail.com',
//                pass: '1011678asd'
//            }
//        });
//
//        const mailOptions = {
//            from: `order.system.applycation@gmail.com`,
//            to: userMail,
//            subject: 'Вы оставили заявку.',
//            html: `<h1>Ваша заявка принята.</h1>
//             <p>Мастер свяжется с вами в ближайшее время. Скачайте наше приложение, где вы сможете общаться с мастерами напрямую, смотреть рейтинги мастеров и оставлять заявки.
//
//                 Ссылка  </p>
//                 <p><b>Ваш логин: ${userMail}</b></p>
//                 <p><b>Ваш пароль: ${pass}</b></p>
//
//                 `
//        };
//
//        return transporter.sendMail(mailOptions, (error, data) => {
//            if (error) {
//
//               console.log(error)
//                return
//            }
//            console.log("Sent!")
//        });
//
//    }
//})