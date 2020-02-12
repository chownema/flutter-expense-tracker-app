import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:path_provider/path_provider.dart';
import 'package:objectdb/objectdb.dart';

import 'package:uuid/uuid.dart';

import 'package:qr_mobile_vision/qr_camera.dart';
// import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';

void main() {
  runApp(MyApp());
}

class Helper {
  static dynamic handleDateTimeParse(item) {
    if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }
}

class DBService {
  Directory appDocDir;
  String appDocPath = '';
  String path = '';
  String pathFolders = '';
  String pathPhotosUrls = '';
  bool isNew = true;

  DBService() {
    initFiles();
  }

  initFiles() async {
    this.appDocDir = await getApplicationDocumentsDirectory();
    this.appDocPath = appDocDir.path;

    this.path = this.appDocPath + 'expenses.db';
    this.pathFolders = this.appDocPath + 'folders.db';
    this.pathPhotosUrls = this.appDocPath + 'photos.db';

    // delete old database file if exists
    File dbFile = File(this.path);
    File dbFolderFile = File(this.pathFolders);
    File dbPohotoUrlsFile = File(this.pathPhotosUrls);

    // check if database already exists
    this.isNew = !await dbFile.exists() &&
        !await dbFolderFile.exists() &&
        !await dbPohotoUrlsFile.exists();
    return Future.value(true);
  }

  init(dataList, folderList, pictureList) async {}

  saveExpense(entity, id) async {
    return this.save(entity, id, this.path);
  }

  getAllExpense() async {
    return this.getAll(this.path);
  }

  getExpense(id) async {
    return this.get(id, this.path);
  }

  deleteExpense(id) async {
    return this.delete(id, this.path);
  }

  saveExpenseFolder(entity, id) async {
    return this.save(entity, id, this.pathFolders);
  }

  getAllExpenseFolder() async {
    return this.getAll(this.pathFolders);
  }

  getExpenseFolder(id) async {
    return this.get(id, this.pathFolders);
  }

  deleteExpenseFolder(id) async {
    return this.delete(id, this.pathFolders);
  }

  saveExpensePhoto(entity, id) async {
    return this.save(entity, id, this.pathPhotosUrls);
  }

  getAllExpensePhoto() async {
    return this.getAll(this.pathPhotosUrls);
  }

  getExpensePhoto(id) async {
    return this.get(id, this.pathPhotosUrls);
  }

  deleteExpensePhoto(id) async {
    return this.delete(id, this.pathPhotosUrls);
  }

  save(entity, id, path) async {
    print(path);
    print(entity);
    final db = ObjectDB(path);
    await db.open(false);
    if (id != null) {
      await db.update({'id': id}, jsonDecode(
          jsonEncode(entity, toEncodable: Helper.handleDateTimeParse)));
    } else {
      await db.insert(jsonDecode(
          jsonEncode(entity, toEncodable: Helper.handleDateTimeParse)));
    }

    var res = await this.get(entity['id'], path);
    print('made');
    print(res);

    await db.close();
  }

  /// Gets all based on greater than 0 cost
  getAll(path) async {
    final db = ObjectDB(path);
    await db.open();

    final res = await db.find({});

    await db.close();
    return res;
  }

  get(id, path) async {
    final db = ObjectDB(path);
    await db.open(false);

    var res = await db.find({'id': id});

    await db.close();

    return res;
  }

  delete(id, path) async {
    final db = ObjectDB(path);
    await db.open(false);

    await db.remove({'id': id});

    await db.close();
  }
}

class ConstantsService {
  static final VIEW_INDEX_FOLDER_LIST = 0;
  static final VIEW_INDEX_EXPENSE_LIST = 1;
  static final VIEW_INDEX_CREATE = 2;
}

class StateService {
  bool isNew = true;
  DBService db;

  StateService(this.db);

  init() async {
    await this.db.initFiles();
    await this.db.init(this.expensesList, this.folderList, this.photoList);

    this.expensesList = await this.db.getAllExpense();
    this.folderList = await this.db.getAllExpenseFolder();
    var pictures = await this.db.getAllExpensePhoto();
    this.isNew = this.db.isNew;

    print('DB CONTENTS');
    print(this.expensesList.toString());
    print(this.folderList.toString());
  }

  List<Map<dynamic, dynamic>> photoList = [];
  List<Map<dynamic, dynamic>> expensesList = [
    {
      'id': 1,
      'name': 'Burger King',
      'desc': 'On the go Burger',
      'cost': 2.00,
      'date': '12/12/12',
      'folder': 'Food'
    },
    {
      'id': 2,
      'name': 'Countdown',
      'desc': 'On the go banana',
      'cost': 2.00,
      'date': '12/12/12',
      'folder': 'Food'
    },
    {
      'id': 3,
      'name': 'Burger Burger',
      'desc': 'Work Meeting with the managers',
      'cost': 60.00,
      'date': '12/12/12',
      'folder': 'Food'
    },
    {
      'id': 4,
      'name': 'AT HOP Card',
      'desc': 'Charging Card',
      'cost': 50.00,
      'date': '12/12/12',
      'folder': 'Transport'
    },
    {
      'id': 5,
      'name': 'Bus Fare',
      'desc': 'Going to work and such',
      'cost': 50.00,
      'date': '12/12/12',
      'folder': 'Transport'
    },
    {
      'id': 6,
      'name': 'Desk R Us',
      'desc': 'Desk for new computer',
      'cost': 200.00,
      'date': '12/12/12',
      'folder': 'Equipment'
    }
  ];
  fetchExpenses(String folder) async {
    this.expensesList = await this.db.getAllExpense();
  }

  getExpenses(String folder) {
    return this
        .expensesList
        .where((element) => element['folder'] == folder)
        .toList();
  }

  saveExpense(expense, nextViewIndex) {
    final int existingIndex = this
        .expensesList
        .indexWhere((element) => element['id'] == expense['id']);
    if (existingIndex != -1) {
      this.expensesList[existingIndex] = expense;
      this.db.saveExpense(expense, expense['id']);
    } else {
      this.expensesList.add(expense);
      print(this.db);
      this.db.saveExpense(expense, null);
    }
    this.currentViewIndex = nextViewIndex;
  }

  List<Map<dynamic, dynamic>> folderList = [
    {'name': 'Food'},
    {'name': 'Transport'},
    {'name': 'Equipment'},
  ];
  getFolderStringList() {
    return this.folderList.map((element) => element['name']).toList();
  }

  int currentViewIndex = ConstantsService.VIEW_INDEX_FOLDER_LIST;
  String currentExpenseFolder = 'Food';
  var currentExpenseItem = {};
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  StateService stateService;
  DBService db;

  MyHomePage({Key key, this.title}) {
    this.db = new DBService();
    this.stateService = new StateService(this.db);
    this.stateService.init();
  }
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StateService stateService;
  DBService db;

  _MyHomePageState() {
    this.db = new DBService();
    this.stateService = new StateService(this.db);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: [
            new ListViewWidgetBuilder(
                this.stateService,
                this.stateService.folderList,
                (item) => {
                      setState(() {
                        this.stateService.currentViewIndex =
                            ConstantsService.VIEW_INDEX_EXPENSE_LIST;
                        this.stateService.currentExpenseFolder = item['name'];
                      })
                    },
                (item) => {print('onRemove' + item)},
                (item) => {print('onShare' + item)},
                (item) => {print('onMoreOptions' + item)},
                (item) => {print('onArchiveItem' + item)}).getView(),
            FutureBuilder(
                future: this
                    .stateService
                    .fetchExpenses(this.stateService.currentExpenseFolder),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return new ListViewWidgetBuilder(
                        this.stateService,
                        this.stateService.getExpenses(
                            this.stateService.currentExpenseFolder),
                        (item) => {
                              setState(() {
                                this.stateService.currentViewIndex =
                                    ConstantsService.VIEW_INDEX_CREATE;
                                this.stateService.currentExpenseItem = item;
                              })
                            },
                        (item) => {print('onRemove' + item)},
                        (item) => {print('onShare' + item)},
                        (item) => {print('onMoreOptions' + item)},
                        (item) => {print('onArchiveItem' + item)}).getView();
                  } else {
                    return new ListView();
                  }
                }),
            new CreateViewWidgetBuilder(
                this.stateService,
                this.stateService.currentExpenseItem,
                this.stateService.currentExpenseFolder,
                this.stateService.getFolderStringList(),
                (item) => {
                      setState(() {
                        var saveItem = {
                          'id': item['id'],
                          'name': item['store'],
                          'desc': item['description'],
                          'cost': item['cost'],
                          'folder': item['folder'],
                          'date': item['date']
                        };
                        this.stateService.saveExpense(saveItem, 0);
                      })
                    }).getView()
          ][this.stateService.currentViewIndex],
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                this.stateService.currentViewIndex =
                    ConstantsService.VIEW_INDEX_CREATE;
                this.stateService.currentExpenseItem = {};
              });
            },
            tooltip: 'Add Expense',
            child: Icon(Icons.add),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ),
        onWillPop: _onWillPop);
  }

  Future<bool> _onWillPop() async {
    if (this.stateService.currentViewIndex ==
        ConstantsService.VIEW_INDEX_FOLDER_LIST) {
      return (await showDialog(
            context: context,
            builder: (context) => new AlertDialog(
              title: new Text('Are you sure?'),
              content: new Text('Do you want to exit an App'),
              actions: <Widget>[
                new FlatButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: new Text('No'),
                ),
                new FlatButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: new Text('Yes'),
                ),
              ],
            ),
          )) ??
          false;
    } else {
      setState(() {
        this.stateService.currentViewIndex--;
      });
      return false;
    }
  }
}

/************************
 *     View Widgets
 ************************/

class CreateViewWidgetBuilder {
  StateService stateService;
  var entity;
  List folders;
  var currentFolder;
  String id;

  final GlobalKey<FormBuilderState> key = GlobalKey<FormBuilderState>();

  Function onSave;

  CreateViewWidgetBuilder(this.stateService, this.entity, this.currentFolder,
      this.folders, this.onSave);

  getView() {
    print('create view entity');
    print(this.entity);
    return ListView(
        padding:
            EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0, bottom: 20.0),
        children: [
          Column(children: [
            FormBuilder(
                key: key,
                initialValue: {
                  'date': DateTime.now(),
                  'folder': this.currentFolder,
                  'store': this.entity['name'],
                  'cost': this.entity['cost'].toString(),
                  'description': this.entity['desc']
                },
                autovalidate: true,
                child: Column(children: getChildren(this.entity)))
          ])
        ]);
  }

  getChildren(entity) {
    return [
      FormBuilderTextField(
        style: TextStyle(fontSize: 50),
        attribute: 'store',
        decoration: InputDecoration(hintText: 'Store Name'),
      ),
      FormBuilderDropdown(
        attribute: 'folder',
        decoration: InputDecoration(labelText: 'Folder'),
        hint: Text('Select Folder'),
        validators: [FormBuilderValidators.required()],
        items: this
            .folders
            .map((folder) =>
                DropdownMenuItem(value: folder, child: Text(folder)))
            .toList(),
      ),
      FormBuilderDateTimePicker(
        attribute: 'date',
        inputType: InputType.date,
        format: DateFormat('yyyy-MM-dd'),
        decoration: InputDecoration(labelText: 'Date'),
      ),
      FormBuilderTextField(
        attribute: 'cost',
        decoration: InputDecoration(labelText: 'Cost (\$)'),
        validators: [FormBuilderValidators.numeric()],
      ),
      FormBuilderTextField(
          attribute: 'description',
          decoration: InputDecoration(labelText: 'Description')),
      Row(children: <Widget>[
        MaterialButton(
          color: Colors.indigo,
          textColor: Colors.white,
          child: Text('Save'),
          onPressed: () {
            if (this.key.currentState.saveAndValidate()) {
              var saveItem = {};

              if (this.entity['id'] == null) {
                saveItem
                  ..addAll({'id': Uuid().v4()})
                  ..addAll(this.key.currentState.value);
              } else {
                saveItem
                  ..addAll({'id': this.entity['id']})
                  ..addAll(this.key.currentState.value);
              }

              this.onSave(saveItem);
            }
          },
        )
      ])
    ];
  }
}

class ListViewWidgetBuilder {
  StateService stateService;
  Function removeItem;
  Function shareItem;
  Function moreOptionsItem;
  Function archiveItem;
  Function tapItem;
  List entityList;

  ListViewWidgetBuilder(this.stateService, this.entityList, this.tapItem,
      this.removeItem, this.shareItem, this.moreOptionsItem, this.archiveItem);

  getView() {
    return ListView(children: this.getChildren(this.entityList));
  }

  List<Widget> getChildren(List list) {
    List<Widget> itemList = [];

    list.forEach((item) {
      itemList.add(new Slidable(
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.25,
        child: Container(
            color: Colors.white,
            child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigoAccent,
                  child: Text(''),
                  foregroundColor: Colors.white,
                ),
                title: Text(item['name']),
                subtitle: Text('Slide for more options'),
                onTap: () => this.tapItem(item))),
        actions: <Widget>[
          IconSlideAction(
            caption: 'Archive',
            color: Colors.indigo,
            icon: Icons.archive,
            onTap: () => this.archiveItem(item),
          ),
          IconSlideAction(
            caption: 'Share',
            color: Colors.indigo,
            icon: Icons.share,
            onTap: () => this.shareItem(item),
          ),
        ],
        secondaryActions: <Widget>[
          IconSlideAction(
            caption: 'More',
            color: Colors.black45,
            icon: Icons.more_horiz,
            onTap: () => this.moreOptionsItem(item),
          ),
          IconSlideAction(
            caption: 'Delete',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () => this.shareItem(item),
          )
        ],
      ));
    });
    return itemList;
  }
}
