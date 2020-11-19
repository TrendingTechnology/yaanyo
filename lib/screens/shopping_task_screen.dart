import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yaanyo/models/shopping_task.dart';
import 'package:yaanyo/services/database_service.dart';
import 'package:yaanyo/services/service_locator.dart';
import 'package:yaanyo/widgets/warning_widget.dart';

import 'authentication/sign_in_screen.dart';

class ShoppingTaskScreen extends StatefulWidget {
  const ShoppingTaskScreen({
    Key key,
    this.gridColor,
    this.storeName,
  }) : super(key: key);

  final Color gridColor;
  final String storeName;

  @override
  _ShoppingTaskScreenState createState() => _ShoppingTaskScreenState();
}

class _ShoppingTaskScreenState extends State<ShoppingTaskScreen> {
  final _taskInputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Stream<QuerySnapshot> shoppingTaskStream;

  Future _addTask() async {
    if (_formKey.currentState.validate()) {
      final shoppingTask = ShoppingTask(
        taskLabel: _taskInputController.text.trim(),
        isDone: false,
        time: Timestamp.now(),
      );

      serviceLocator<DatabaseService>().addShoppingTask(
        storeName: widget.storeName,
        shoppingTask: shoppingTask,
      );
      _taskInputController.clear();
    }
  }

  void _toggleShoppingTask(bool toggle, String taskLabel) {
    final ShoppingTask shoppingTask = ShoppingTask(
        isDone: toggle, taskLabel: taskLabel, time: Timestamp.now());

    serviceLocator<DatabaseService>().toggleShoppingTask(
      storeName: widget.storeName,
      shoppingTask: shoppingTask,
    );
  }

  @override
  void initState() {
    super.initState();
    shoppingTaskStream = serviceLocator<DatabaseService>()
        .getShoppingTaskStream(widget.storeName);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        backgroundColor: widget.gridColor,
        appBar: buildAppBar(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder(
                stream: shoppingTaskStream,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      return WarningWidget(
                          iconData: Icons.warning_amber_rounded,
                          label:
                              'No Internet Connection \n Please make sure you\'re online',
                          buttonLabel: 'Try again',
                          buttonOnPress: () {});
                    case ConnectionState.waiting:
                      return Center(child: CircularProgressIndicator());
                    default:
                      if (snapshot.data.docs.isEmpty) {
                        return WarningWidget(
                            iconData: Icons.hourglass_empty,
                            label: 'No Tasks at hand ',
                            buttonOnPress: () {});
                      } else if (snapshot.hasError) {
                        return WarningWidget(
                          iconData: Icons.warning_amber_rounded,
                          label:
                              'Something went wrong. \n Please sign in again!',
                          buttonLabel: 'Sign in again',
                          buttonOnPress: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignInScreen())),
                        );
                      } else if (snapshot.hasData) {
                        return ListView.builder(
                          padding: EdgeInsets.only(left: 18),
                          itemCount: snapshot.data.documents.length,
                          itemBuilder: (BuildContext context, int index) {
                            final data = snapshot.data.docs[index].data();

                            return Row(
                              children: <Widget>[
                                Icon(
                                  Icons.reorder_rounded,
                                  color: Colors.black45,
                                ),
                                Checkbox(
                                  visualDensity: VisualDensity.compact,
                                  value: data['isDone'],
                                  onChanged: (toggle) => _toggleShoppingTask(
                                    toggle,
                                    data['taskLabel'],
                                  ),
                                ),
                                Text(
                                  data['taskLabel'],
                                  style: Theme.of(context).textTheme.bodyText1,
                                ),
                              ],
                            );
                          },
                        );
                      }
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.gridColor,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _taskInputController,
                        validator: (value) =>
                            value.isEmpty ? 'Field can not be empty' : null,
                        textInputAction: TextInputAction.go,
                        onFieldSubmitted: (value) => _addTask(),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Add task here...',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _addTask(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(widget.storeName),
      backgroundColor: widget.gridColor,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          itemBuilder: (BuildContext context) {
            return {''}.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
          onSelected: (value) {
            // Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
