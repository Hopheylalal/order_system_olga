import 'package:flutter/material.dart';

class Blocked extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Аккаунт заюлокирован',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Text('Ваша учетная запись заблокрованна администрацией сервиса.'),
        ),
      ),
    );
  }
}
