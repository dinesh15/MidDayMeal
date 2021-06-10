import 'package:auto_size_text/auto_size_text.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../screens/AddSchoolScreen.dart';
import '../screens/SchoolMonthlyReport.dart';
import '../screens/StudentHomeScreen.dart';

class GovtHomeScreen extends StatefulWidget {
  const GovtHomeScreen({Key? key}) : super(key: key);

  @override
  _GovtHomeScreenState createState() => _GovtHomeScreenState();
}

class _GovtHomeScreenState extends State<GovtHomeScreen> {
  final fbAuth = FirebaseAuth.instance;
  final fbDB = FirebaseDatabase.instance;
  String name = '', status = 'created';
  bool _isLoading = false;
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    setState(() {
      _isLoading = true;
    });
    final snap =
        await fbDB.reference().child("users/${fbAuth.currentUser!.uid}").once();
    name = snap.value['name'];
    status = snap.value['status'];
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mqs = MediaQuery.of(context).size;
    final ref = fbDB.reference();
    return Container(
      color: Colors.white,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  title: AutoSizeText(
                    name,
                    style: TextStyle(fontSize: 30, color: Colors.black),
                  ),
                  actions: [
                    Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: IconButton(
                        alignment: Alignment.bottomRight,
                        onPressed: () {
                          fbAuth.signOut();
                        },
                        icon: Icon(
                          Icons.logout,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                body: status == 'created'
                    ? NotVerified(
                        fbAuth: fbAuth,
                        name: name,
                      )
                    : status == 'rejected'
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AutoSizeText(
                                    "Your request has been rejected by the Admin"),
                                TextButton(
                                  onPressed: () {
                                    fbAuth.signOut();
                                  },
                                  child: Text("Go back"),
                                )
                              ],
                            ),
                          )
                        : ListView(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => AddSchool(),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.all(10),
                                  height: mqs.height * 0.15,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    boxShadow: kElevationToShadow[1],
                                    borderRadius: BorderRadius.circular(10),
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                  // gradient: LinearGradient(
                                  //     colors: [
                                  //       Colors.purple.shade800,
                                  //       Theme.of(context).primaryColorDark
                                  //     ],
                                  //     begin: Alignment.topLeft,
                                  //     end: Alignment.bottomRight)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            height: 57,
                                            width: 50,
                                            child: Icon(
                                              Icons.school_sharp,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    width: 2,
                                                    color: Theme.of(context)
                                                        .primaryColorDark),
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      AutoSizeText(
                                        "Add School",
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              StreamBuilder(
                                stream:
                                    ref.child("schools").orderByKey().onValue,
                                builder: (ctx, snap) {
                                  if (snap.connectionState ==
                                      ConnectionState.waiting)
                                    return Center(
                                        child: CircularProgressIndicator());
                                  final event = snap.data as Event;
                                  final result = event.snapshot.value == null
                                      ? {}
                                      : event.snapshot.value as Map;
                                  final today = DateTimeFormat.format(
                                      DateTime.now(),
                                      format: 'd');
                                  final month = DateTimeFormat.format(
                                      DateTime.now(),
                                      format: 'M');

                                  return Column(
                                    children: result.keys.map((e) {
                                      var recievedAllItemsCount = 0,
                                          notRecievedAllItemsCount = 0,
                                          percent = 0.0;
                                      final todaysData =
                                          result[e]['reportedData'] == null
                                              ? null
                                              : result[e]['reportedData'][month]
                                                  [today];
                                      if (todaysData != null) {
                                        todaysData.keys.forEach((key) {
                                          bool recievedAllItems = true;
                                          todaysData[key].forEach((k, v) {
                                            if (k != 'imageUrl' && !v)
                                              recievedAllItems = false;
                                          });
                                          if (recievedAllItems)
                                            recievedAllItemsCount += 1;
                                          else
                                            notRecievedAllItemsCount += 1;
                                        });
                                        // print(recievedAllItemsCount);
                                        percent = todaysData.length /
                                            int.parse(
                                                result[e]['studentCount']);
                                      }
                                      // print(percent);
                                      return InkWell(
                                        onLongPress: () {
                                          showDialog(
                                              context: context,
                                              builder: (ctx) {
                                                return AlertDialog(
                                                  title: Text(
                                                    "Are you sure?",
                                                  ),
                                                  content: Text(
                                                      "You are going to remove this school!"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(true);
                                                        },
                                                        child: Text("Yes")),
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(false);
                                                        },
                                                        child: Text("No"))
                                                  ],
                                                );
                                              }).then((value) {
                                            if (value != null && value) {
                                              ref
                                                  .child(
                                                      "schools/${e.toString()}")
                                                  .remove();
                                            }
                                          });
                                        },
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (ctx) {
                                                return SchoolMonthlyReport(
                                                  reportedData: result[e],
                                                  schoolName: e.toString(),
                                                  month: month,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: EdgeInsets.fromLTRB(
                                              10, 0, 10, 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.white,
                                            boxShadow: kElevationToShadow[1],
                                          ),
                                          padding: EdgeInsets.only(top: 15),
                                          child: Column(
                                            children: [
                                              AutoSizeText(
                                                e,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Theme.of(context)
                                                      .primaryColorDark,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 15,
                                              ),
                                              Stack(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      color: Theme.of(context)
                                                          .primaryColorLight,
                                                    ),
                                                    height: mqs.height * 0.06,
                                                    width: mqs.width - 40,
                                                  ),
                                                  Container(
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      color: Theme.of(context)
                                                          .primaryColorDark,
                                                    ),
                                                    height: mqs.height * 0.06,
                                                    width: (mqs.width - 40) *
                                                        percent,
                                                    child: AutoSizeText(
                                                      todaysData == null
                                                          ? ""
                                                          : todaysData.length
                                                              .toString(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Chip(
                                                    backgroundColor:
                                                        Colors.green,
                                                    label: AutoSizeText(
                                                      "Recieved: $recievedAllItemsCount",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Chip(
                                                    backgroundColor: Colors.red,
                                                    label: AutoSizeText(
                                                      "Not recieved: $notRecievedAllItemsCount",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Chip(
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .primaryColor,
                                                    label: AutoSizeText(
                                                      "Students: ${result[e]['studentCount']}",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
              ),
            ),
    );
  }
}
