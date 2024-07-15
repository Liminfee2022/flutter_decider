import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decider/extensions/string_extensions.dart';
import 'package:decider/models/account_model.dart';
import 'package:decider/models/question_model.dart';
import 'package:decider/services/auth_service.dart';
import 'package:decider/views/history_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeViews extends StatefulWidget {
  const HomeViews({super.key, required this.account});
  final Account account;

  @override
  State<HomeViews> createState() => _HomeViewsState();
}

class _HomeViewsState extends State<HomeViews> {
  String _answer = '';
  bool _askBtnActive = false;
  final TextEditingController _questionController = TextEditingController();
  final Question _question = Question();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text(
            'Decider',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HistoryView(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Decision Left: ${widget.account.bank}'),
                ),
                const Spacer(),
                _buildQuestionForm(context),
                const Spacer(
                  flex: 3,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Account Type: Free'),
                ),
                Text('${context.read<AuthService>().currentUser?.uid}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionForm(BuildContext context) {
    return Column(
      children: [
        Text(
          'Should I',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Padding(
          padding: const EdgeInsets.only(
            bottom: 10.0,
            left: 30.0,
            right: 30.0,
          ),
          child: TextField(
            decoration: const InputDecoration(helperText: 'Enter A Question'),
            keyboardType: TextInputType.multiline,
            controller: _questionController,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              setState(() {
                _askBtnActive = value.isNotEmpty;
              });
            },
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: _askBtnActive == true ? _answerQuestion : null,
          child: const Text(
            'Ask',
            style: TextStyle(color: Colors.white),
          ),
        ),
        _questionAndAnswer(context),
      ],
    );
  }

  Widget _questionAndAnswer(BuildContext context) {
    if (_answer.isEmpty) return Container();

    return Column(
      children: [
        Text('Should I ${_question.query} ?'),
        Text(
          'Answer: ${_answer.capitalize()}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  void _answerQuestion() async {
    setState(() {
      _answer = _getAnswer();
    });
    _question.query = _questionController.text;
    _question.answer = _answer;
    _question.created = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.account.uid)
        .collection('questions')
        .add(_question.toJson());

    //Update the document
    widget.account.bank -= 1;
    widget.account.nextFreeQuestion = DateTime.now().add(Duration(seconds: 5));
    
    await FirebaseFirestore.instance
    .collection('users')
    .doc(widget.account.uid)
    .update(widget.account.toJson());

    _questionController.text = '';
  }
}

String _getAnswer() {
  var answerOptions = ['yes', 'no', 'definitely', 'not right now'];
  return answerOptions[Random().nextInt(answerOptions.length)];
}
