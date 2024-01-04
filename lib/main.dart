import 'package:flutter/material.dart';
import 'models/Exam.dart';
import 'calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('bd_logo');

  final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true, onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {});

  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: (String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  });
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoggedIn = false;
  var title = '201117';
  List<Exam> exams = [];
  bool toggleForm = false;

  final _inputKey = GlobalKey<FormState>();
  final _messangerKey = GlobalKey<ScaffoldMessengerState>();

  String? name = "";
  String? username = "";
  DateTime currentDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  late TextEditingController txt;
  late TextEditingController user;

  @override
  void initState() {
    super.initState();
    txt = TextEditingController()
      ..addListener(() {
      });

    user = TextEditingController()
      ..addListener(() {
      });
  }

  @override
  void dispose() {
    txt.dispose();
    user.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: currentDate, firstDate: DateTime(2015), lastDate: DateTime(2050));
    if (pickedDate != null && pickedDate != currentDate)
      setState(() {
        currentDate = pickedDate;
      });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked_s = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        });

    if (picked_s != null && picked_s != selectedTime)
      setState(() {
        selectedTime = picked_s;
      });
  }

  Future<List<Exam>> _get(String username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? examsString = await prefs.getString(username);

    List<Exam> examsList = [];

    if (examsString != null) examsList = Exam.decode(examsString);

    return examsList;
  }

  Future<void> _set(String username, List<Exam> exams) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String encodedData = Exam.encode(exams);

    await prefs.setString(username, encodedData);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messangerKey,
      title: '201117',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (isLoggedIn)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    toggleForm = !toggleForm;
                  });
                },
              ),
            if (isLoggedIn)
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    toggleForm = false;
                  });
                },
              ),
          ],
        ),
        body: isLoggedIn
            ? SingleChildScrollView(
            child: Column(children: <Widget>[
              if (toggleForm)
                Card(
                    elevation: 5,
                    child: Form(
                      key: _inputKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.all(15),
                              child: TextFormField(
                                  controller: txt,
                                  decoration: InputDecoration(
                                    icon: Icon(Icons.book_outlined),
                                    hintText: 'Name of the exam',
                                    labelText: 'Exam name *',
                                  ),
                                  validator: (inputString) {
                                    name = inputString;
                                    if (inputString!.length < 1) {
                                      return 'Please enter a valid name';
                                    }
                                    return null;
                                  })),
                          Padding(
                            padding: EdgeInsets.all(1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(padding: EdgeInsets.all(20), child: Text(currentDate.toString().split(" ")[0])),
                                ElevatedButton(
                                  onPressed: () => _selectDate(context),
                                  child: Text('Select date'),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(padding: EdgeInsets.all(20), child: Text(selectedTime.format(context))),
                                ElevatedButton(
                                  onPressed: () => _selectTime(context),
                                  child: Text('Select time'),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_inputKey.currentState!.validate()) {
                                  name = txt.text;
                                  currentDate = new DateTime(currentDate.year, currentDate.month, currentDate.day, selectedTime.hour, selectedTime.minute);
                                  Exam obj = new Exam(name: name!, date: currentDate, time: selectedTime);
                                  scheduler(obj);
                                  exams.add(obj);
                                  _set(username!, exams);
                                  setState(() {
                                    this.exams = exams;
                                    txt.text = "";
                                    name = "";
                                    currentDate = DateTime.now();
                                    selectedTime = TimeOfDay.now();
                                  });
                                  _messangerKey.currentState?.showSnackBar(SnackBar(content: Text('Exam added successfully')));
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ),
                        ],
                      ),
                    )),
              Padding(
                  padding: EdgeInsets.all(15),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(5),
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TableEventsExample(this.exams)),
                            ),
                            child: const Text('Terms calendar'),
                          )))),
              Padding(
                  padding: EdgeInsets.all(15),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(5),
                          child: ElevatedButton(
                            onPressed: () => setState(() => {
                              username = "",
                              isLoggedIn = false
                            }),
                            child: const Text('Logout'),
                          )))),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: exams.length,
                itemBuilder: (contx, index) {
                  return Column(children: [
                    Card(
                      key: Key(exams[index].name!),
                      elevation: 2,
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(18),
                        child: Column(children: [
                          Container(padding: EdgeInsets.all(5), margin: EdgeInsets.all(5), child: Text(exams[index].name.toString(), style: TextStyle(fontWeight: FontWeight.bold))),
                          Container(padding: EdgeInsets.all(5), margin: EdgeInsets.all(5), child: Text(exams[index].date.toString().split(" ")[0] + " " + exams[index].time!.format(context), style: TextStyle(color: Colors.grey))),
                        ]),
                      ),
                    ),
                  ]);
                },
              ),
            ]))
            : Card(
            elevation: 5,
            child: Form(
              key: _inputKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                      padding: EdgeInsets.all(15),
                      child: TextFormField(
                          controller: user,
                          decoration: InputDecoration(
                            icon: Icon(Icons.account_circle),
                            hintText: 'Type in your username',
                            labelText: 'Username *',
                          ),
                          validator: (inputString) {
                            username = inputString;
                            if (inputString!.length < 1) {
                              return 'Please enter a valid username';
                            }
                            return null;
                          })),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_inputKey.currentState!.validate()) {
                          username = user.text;
                          user.text = "";
                          _get(username!).then((List<Exam> examsList) => {
                            setState(() {
                              this.exams = examsList;
                              isLoggedIn = true;
                            })
                          });
                          _messangerKey.currentState?.showSnackBar(SnackBar(content: Text('Logged in successfully')));
                        }
                      },
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  void scheduler(Exam exam) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails('exam_notif_channel_id', 'exam_notif_channel', channelDescription: 'Channel for Exam notification', icon: 'bd_logo', sound: RawResourceAndroidNotificationSound('a_long_cold_sting'), largeIcon: DrawableResourceAndroidBitmap('bd_logo'));

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(sound: 'a_long_cold_sting.wav', presentAlert: true, presentBadge: true, presentSound: true);

    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    var dayBefore = exam.date?.subtract(const Duration(days: 1));

    await flutterLocalNotificationsPlugin.schedule(0, 'Exam', exam.name, dayBefore!, platformChannelSpecifics);
  }
}
