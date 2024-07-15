import 'package:decider/extensions/string_extensions.dart';
import 'package:decider/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text('Should I ${question.query}'),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    question.answer!.capitalize(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(DateFormat('MM/dd/yyyy')
                      .format(question.created!)
                      .toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
