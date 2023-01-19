import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reportingapp1/controller/controller.dart';
import 'package:reportingapp1/screen/tabbar/tabbarClickPage.dart';

class TabbarBodyView extends StatefulWidget {
  @override
  State<TabbarBodyView> createState() => _TabbarBodyViewState();
}

class _TabbarBodyViewState extends State<TabbarBodyView> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Consumer<Controller>(
        builder: (context, value, child) {
          return AbsorbPointer(
            absorbing: value.isReportLoading ? true : false,
            child: Column(
              children: [
                Container(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        DefaultTabController(
                          length: value.tabList.length, // length of tabs
                          initialIndex: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Container(
                                // color: P_Settings.bodyTabColor,
                                child: TabBar(
                                    physics: NeverScrollableScrollPhysics(),
                                    labelColor: Colors.red,
                                    indicatorWeight: 3,
                                    indicatorColor: Colors.red,
                                    unselectedLabelColor: Colors.black,
                                    labelStyle:
                                        TextStyle(fontWeight: FontWeight.w500),
                                    tabs: value.tabList
                                        .map((e) => Tab(
                                              text: e.tabName.toString(),
                                            ))
                                        .toList()),
                              ),
                              Container(
                                height:
                                    size.height * 0.85, //height of TabBarView
                                decoration: BoxDecoration(
                                    border: Border(
                                        top: BorderSide(
                                            color: Colors.grey, width: 0.5))),
                                child: TabBarView(
                                  physics: NeverScrollableScrollPhysics(),
                                  children: value.tabList.map((e) {
                                    return customContainer(e.tabId.toString());
                                  }).toList(),
                                ),
                              )
                            ],
                          ),
                        ),
                      ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

//////////////////////////////////////////////////////////////////////////////////////////
  Widget customContainer(String e) {
    return Consumer<Controller>(
      builder: (context, value, child) {
        return Container(
          child: TabbarClickPage(
            tabId: e,
            b_id: value.brId!,
          ),
        );
      },
    );
  }
}
