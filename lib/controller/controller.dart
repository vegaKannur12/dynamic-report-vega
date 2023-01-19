import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reportingapp1/components/customSnackbar.dart';
import 'package:reportingapp1/components/externalDir.dart';
import 'package:reportingapp1/components/globalData.dart';
import 'package:reportingapp1/components/networkConnection.dart';
import 'package:reportingapp1/model/menuDatas.dart';
import 'package:reportingapp1/model/registrationModel.dart';
import 'package:http/http.dart' as http;
import 'package:reportingapp1/screen/homeScreen.dart';
import 'package:reportingapp1/services/dbHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_to_hex/string_to_hex.dart';

class Controller extends ChangeNotifier {
  String clicked = "0";
  String? fp;
  String? cid;
  ExternalDir externalDir = ExternalDir();
  int? generatedColorInt;
  String? cname;
  String? sof;
  int? qtyinc;
  List<CD> c_d = [];
  String? firstMenu;
  String? tabId;
  String? brId;
  String? showGraph;
  String? date_criteria;
  String? customIndex;
  bool isLoading = false;
  bool isLoginLoad = false;

  bool isReportLoading = false;
  bool isSubReportLoading = false;

  String? _string;
  Color? generatedColor;

  String? idd;
  String? menu_index;
  String? tab_index;

  bool? dateApplyClicked;
  String? fromDate;
  String id = "";
  List<String> barColor = [];
  String? selected;
  String? todate;
  var reportjson;
  Map graphMap = {};

  List<String> legends = [];
  List<String> colorList = [];
  List<Color> colorListCopy = [];

  List<Map<String, dynamic>> listColor = [];

  Color? colorDup;
  bool menuClick = false;
  List<Map<String, dynamic>> list = [];
  List<Map<String, dynamic>> sublist = [];

  List<TabsModel> customMenuList = [];
  List<Map<String, dynamic>> branches = [];

  List<TabsModel> tabList = [];
  List<Map<String, dynamic>> legendList = [];

  List<bool> descTextShowFlag = [];
  List<Map<String, dynamic>> menuList = [];
  String urlgolabl = Globaldata.apiglobal;

/////////////////////////////////////////////
  Future<RegistrationData?> postRegistration(
      String company_code,
      String? fingerprints,
      String phoneno,
      String deviceinfo,
      BuildContext context) async {
    NetConnection.networkConnection(context).then((value) async {
      print("Text fp...$fingerprints---$company_code---$phoneno---$deviceinfo");
      print("company_code.........$company_code");
      // String dsd="helloo";
      String appType = company_code.substring(10, 12);
      print("apptytpe----$appType");
      if (value == true) {
        try {
          Uri url =
              Uri.parse("https://trafiqerp.in/order/fj/get_registration.php");
          Map body = {
            'company_code': company_code,
            'fcode': fingerprints,
            'deviceinfo': deviceinfo,
            'phoneno': phoneno
          };
          print("body----${body}");
          isLoginLoad = true;
          notifyListeners();
          http.Response response = await http.post(
            url,
            body: body,
          );
          print("body ${body}");
          var map = jsonDecode(response.body);
          print("map register ${map}");
          RegistrationData regModel = RegistrationData.fromJson(map);

          sof = regModel.sof;
          fp = regModel.fp;
          String? msg = regModel.msg;
          print("fp----- $fp");
          print("sof----${sof}");

          if (sof == "1") {
            print("apptype----$appType");
            if (appType == 'LR') {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              /////////////// insert into local db /////////////////////
              late CD dataDetails;
              String? fp1 = regModel.fp;
              print("fingerprint......$fp1");
              prefs.setString("fp", fp!);
              String? os = regModel.os;
              regModel.c_d![0].cid;
              cid = regModel.cid;
              prefs.setString("cid", cid!);

              cname = regModel.c_d![0].cnme;
              print("cname ${cname}");

              prefs.setString("cn", cname!);
              notifyListeners();

              await externalDir.fileWrite(fp1!);

              for (var item in regModel.c_d!) {
                print("ciddddddddd......$item");
                c_d.add(item);
              }
              // verifyRegistration(context, "");

              isLoginLoad = false;
              notifyListeners();

              prefs.setString("os", os!);

              // prefs.setString("cname", cname!);

              String? user = prefs.getString("userType");

              print("fnjdxf----$user");

              await ReportDB.instance
                  .deleteFromTableCommonQuery("companyRegistrationTable", "");
              var res =
                  await ReportDB.instance.insertRegistrationDetails(regModel);
              getInitializeApi(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            } else {
              CustomSnackbar snackbar = CustomSnackbar();
              snackbar.showSnackbar(context, "Invalid Apk Key", "");
            }
          }
          /////////////////////////////////////////////////////
          if (sof == "0") {
            CustomSnackbar snackbar = CustomSnackbar();
            snackbar.showSnackbar(context, msg.toString(), "");
          }

          notifyListeners();
        } catch (e) {
          print(e);
          return null;
        }
      }
    });
  }

  ///////////////////////////////////////////////////////////
  getInitializeApi(BuildContext context) async {
    var res;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cid = prefs.getString("cid");

    print("cid----$cid");
    NetConnection.networkConnection(context).then((value) async {
      if (value == true) {
        try {
          Uri url = Uri.parse("$urlgolabl/initialize.php");
          Map body = {
            'c_id': cid,
          };
          isLoading = true;
          notifyListeners();
          http.Response response = await http.post(
            url,
            body: body,
          );

          var map = jsonDecode(response.body);

          print("menu---------$map");
          MenuModel menuModel = MenuModel.fromJson(map);

          tabList.clear();
          customMenuList.clear();
          for (var item in menuModel.tabs!) {
            if (item.menuType == "0") {
              tabList.add(item);
            } else {
              customMenuList.add(item);
            }
          }
          tabId = tabList[0].tabId.toString();
          branches.clear();
          if (map["branchs"] != null && map["branchs"].length > 0) {
            print("haiiiii");
            List sid = map["branchs"][0]["branch_ids"].split(',');
            List sname = map["branchs"][0]["branch_names"].split(',');
            selected = sname[0];
            brId = sid[0];
            for (int i = 0; i < sid.length; i++) {
              Map<String, dynamic> ma = {
                "branch_id": sid[i],
                "branch_name": sname[i]
              };

              branches.add(ma);
            }

            print("branches----------------$branches");

            // for (var item in map["branchs"]) {
            //   branches.add(item);
            // }

            // selected = branches[0]["branch_name"];
            // brId = branches[0]["branch_id"];
          }

          print("branches--------$branches");
          print("customMenuList---------------$customMenuList");

          isLoading = false;
          notifyListeners();
        } catch (e) {
          print(e);
          return null;
        }
      }
    });
  }

///////////////////////////////////////////////////////////////////
  setDate(String date1, String date2) {
    fromDate = date1;
    todate = date2;
    print("gtyy----$fromDate----$todate");
    notifyListeners();
  }

///////////////////////////////////////////////////////////////////
  getData() {
    List<Map<String, dynamic>> barListShow = [];
    list = [
      {
        "id": "0",
        "title": "Sale1",
        "sum": "NYY",
        "align": "LRR",
        "width": "60,20,20",
        "data": [
          {"date": "4-2022", "Qty": "61703110", "val(k)": "61703110.07"},
          {"date": "5-2022", "Qty": "61703110", "val(k)": "61703110.07"},
          {"date": "6-2022", "Qty": "61703110", "val(k)": "61703110.07"},
        ]
      }
    ];
    // list = [
    //   {
    //     "id": "0",
    //     "title": "Sale Report1",
    //     "sum": "NYY",
    //     "align": "LRR",
    //     "width": "60,20,20",
    //     "data": [
    //       {"date": "20/10/2022", "amount1": "100", "amount2": "327"},
    //       {"date": "4/8/2022", "amount1": "200", "amount2": "190"},
    //       {"date": "2/10/2022", "amount1": "300", "amount2": "206"},
    //       {"date": "1/2/2022", "amount1": "400", "amount2": "100"},
    //     ]
    //   },
    //   // {
    //   //   "id": "1",
    //   //   "title": "anushak",
    //   //   "sum": "NY",
    //   //   "align": "LR",
    //   //   "width": "60,40",
    //   //   "data": [
    //   //     {"date": "20/10/2022", "amount2": "100"},
    //   //     {"date": "4/8/2022", "amount2": "200"},
    //   //     {"date": "2/10/2022", "amount2": "300"},
    //   //     {"date": "1/10/2022", "amount2": "100"},
    //   //     {"date": "6/8/2022", "amount2": "1000"},
    //   //     // {"date": "8/10/2022", "amount2": "400"},
    //   //   ]
    //   // },
    //   // {
    //   //   "id": "2",
    //   //   "title": "Sale Report3",
    //   //   "data": [
    //   //     {
    //   //       "date": "20/10/2022",
    //   //       "amount1": "10",
    //   //     },
    //   //     {
    //   //       "date": "4/8/2022",
    //   //       "amount1": "200",
    //   //     },
    //   //     {
    //   //       "date": "2/10/2022",
    //   //       "amount1": "300",
    //   //     },
    //   //     {
    //   //       "date": "1/2/2022",
    //   //       "amount1": "400",
    //   //     },
    //   //   ]
    //   // },
    // ];

    descTextShowFlag = List.generate(list.length, (index) => false);
  }

  //////////////////////////////////////////////////////////////////////////////
  loadReportData(BuildContext context, String tab_id, String? fromdate,
      String? tilldate, String b_id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cid = prefs.getString("cid");
    NetConnection.networkConnection(context).then((value) async {
      if (value == true) {
        try {
          print("pishkuu---$fromDate----$tilldate");
          Uri url = Uri.parse("$urlgolabl/load_report.php");
          Map body = {
            "c_id": cid,
            "b_id": b_id,
            "tab_id": tab_id,
            "from_date": fromdate,
            "till_date": tilldate
          };
          print("load report body----$body");
          if (type == "sublist") {
            isSubReportLoading = true;
            notifyListeners();
          } else {
            isReportLoading = true;
            notifyListeners();
          }

          http.Response response = await http.post(
            url,
            body: body,
          );
          var map = jsonDecode(response.body);
          print("load report data------$map");
          list.clear();
          if (map != null) {
            for (var item in map) {
              list.add(item);
            }
          }
          if (type == "sublist") {
            isSubReportLoading = false;
            notifyListeners();
          } else {
            isReportLoading = false;
            notifyListeners();
          }
        } catch (e) {
          print(e);
          return null;
        }
      }
    });
    notifyListeners();
  }

////////////////////////////////////////////////////////////////
  setShowHideText(bool value, int index) {
    print("bbdsbd-----$value");
    descTextShowFlag[index] = value;
    notifyListeners();
  }

  /////////////////////////////////////////////////////////////////
  getBarData(List<dynamic> listTest) {
    print("listTest----$listTest");
    List<Map<String, dynamic>> listMap = [];
    Map<String, dynamic> finalList = {};
    List<Map<String, dynamic>> barDataList = [];
    Map<String, dynamic> barDataMap = {};
    // List listTest = [
    //   {"date": "20/10/2022", "amount1": "100", "amount2": "327"},
    //   {"date": "4/8/2022", "amount1": "200", "amount2": "190"},
    //   {"date": "2/10/2022", "amount1": "300", "amount2": "206"},
    //   {"date": "1/2/2022", "amount1": "400", "amount2": "100"},
    // ];
    int c = listTest[0].length;
    Map tempMap = {};
    List<Map<String, dynamic>> data = [];
    for (int j = 1; j < c; j++) {
      data = [];
      barColor = [];
      for (int i = 0; i < listTest.length; i++) {
        // data.add(listTest[i]);
        tempMap = listTest[i];
        String domain = tempMap.values.elementAt(0);
        double measure = double.parse(tempMap.values.elementAt(j));
        id = tempMap.keys.elementAt(j);
        barColor.add(id);
        // String _string = StringToHex.toHexString(sCon);
        Map<String, dynamic> mapTest = {"domain": domain, "measure": measure};
        data.add(
            {"domain": domain, "measure": measure, "colorId": colorList[j]});
      }

      barDataList.add({
        "id": id,
        "data": data,
      });
    }

    print("dnzsndsm-------$barDataList");
    graphMap = {"barData": barDataList};
    print("graphMap----$graphMap");

    return barDataList;
    // reportjson = jsonEncode(graphMap);
  }

  //////////////////////////////////////////////////////////////
  getLegends(List<dynamic> l, String title) {
    Map<String, dynamic> c = {};
    colorList.clear();

    print("from-----$l---");
    listColor.clear();
    legends = [];
    int keyIndex = 0;
    l[0].keys.forEach((key) {
      print("key----$key");
      int key1 = keyIndex * 1215;
      // textToColor(key, title);
      Color color1 = textToColor(key1.toString(), title, key);
      c = {
        key: color1,
      };

      // listColor.add(c);
      legends.add(key);
      keyIndex = keyIndex + 1;
    });

    print("color and id----$listColor");
  }

/////////////////////////////////////////////////////////////////
  // setColor(Color color, String id) {
  //   print("idd---------$color----$id");
  //   // if (idd != id) {
  //   //   print("cdfk-----$color");
  //   //   legendList.add({'id': id, 'color': color});
  //   //   idd = id;
  //   // }
  //   if (colorDup != color) {
  //     colorList.add(color);
  //     colorDup = color;
  //   }

  //   // notifyListeners();
  // }

/////////////////////////////////////////////////////////////////
  textToColor(String id, String title, String key) {
    DateTime date = DateTime.now();
    print("date---$id---$date");
    String sdte = DateFormat('ddMM').format(date);
    print("iso ----${sdte}");
    String reverseId = id.split('').reversed.join('');
    String sCon = reverseId + sdte + title;
    try {
      generatedColor = Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0)
          .withOpacity(1.0);
      // _string = StringToHex.toHexString(sCon);
      // generatedColor = Color(StringToHex.toColor(_string));
      // generatedColorInt = StringToHex.toColor(_string);
      print("_string---$generatedColorInt--$_string----$generatedColor");
    } catch (e) {
      print("exception-----$e");
      String sCon2 = id + "1994";
      String reversed = sCon2.split('').reversed.join('');
      _string = StringToHex.toHexString(reversed);
      generatedColor = Color(StringToHex.toColor(_string));
      // generatedColorInt = StringToHex.toColor(_string);
    }
    var hex = '#${generatedColor!.value.toRadixString(16)}';
    colorList.add(hex);
    // listColor.add(generatedColor!);
    print("colorList--------$colorList");
    return generatedColor;
  }

/////////////////////////////////////////////////////////////////
  setDropdowndata(String s) {
    brId = s;
    for (int i = 0; i < branches.length; i++) {
      if (branches[i]["branch_id"] == s) {
        selected = branches[i]["branch_name"];
      }
    }
    print("s------$s");
    notifyListeners();
  }

  setMenuClick(bool value) {
    menuClick = value;
    print("menu click------$menuClick");

    notifyListeners();
  }

  setMenuindex(String ind) {
    menu_index = ind;
    tab_index = ind;
    print("mnadmn------$tab_index");
    notifyListeners();
  }

  setCustomReportIndex(String inde) {
    customIndex = inde;
    print("customIndex------$customIndex");
    notifyListeners();
  }

  setDateCriteria(String inde) {
    date_criteria = inde;
    print("date_criteria------$date_criteria");
    notifyListeners();
  }

  setClicked(String clik) {
    clicked = clik;
    notifyListeners();
  }
}
