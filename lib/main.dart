import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram/shop.dart';
import './style.dart' as style;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';


import 'notification.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(
    providers:[
      ChangeNotifierProvider(create:(c)=>Store1()),
      ChangeNotifierProvider(create:(c)=>Store2()),
    ],
        child: MaterialApp(
            theme: style.theme,
            home:MyApp()
          ),
      ),
  );
}

class Store2 extends ChangeNotifier{
  var name = 'das kim';
}

class Store1 extends ChangeNotifier{
  var follow=0;
  var friends= false;
  var profileImage=[];
  
  getData() async {
    var result =await http.get(Uri.parse('https://codingapple1.github.io/app/profile.json'));
    var result2 = jsonDecode(result.body);
    profileImage=result2;
    notifyListeners();
  }
  
  addFollow(){
    if (friends==false){
      follow++;
      friends=true;
    } else {
      follow--;
      friends=false;
      friends=false;
    }
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int tab=0;
  var urlData=[];
  var userImage; //사용자 입력 이미지 수집
  var userContent; //유저 입력 콘텐트 수집 자식이 부모 변수 수정 (함수로 수정함수 보내기)

  addMyData(){
    var myData={
      'id':urlData.length,
      'image':userImage,
      'likes':5,
      'date' : 'July 25',
      'content': userContent,
      'liked':false,
      'user':'DasKim'
    };

    setState(() {
      urlData.insert(0,myData);
    });
  }


  setUserContent(a){
    setState(() {
      userContent=a;
    });
  }


  getData() async{
    var result = await http.get(Uri.parse('https://codingapple1.github.io/app/data.json'));
    setState(() {
      urlData=jsonDecode(result.body);
    });

    print(urlData);

  }

  saveData() async{
    var storage = await SharedPreferences.getInstance();
    storage.setString('name','john');
    var result=storage.get('name');
    print(result);
  }

  @override
  void initState() {
    super.initState();
    saveData();
    getData();
    initNotification(context);

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(child:Text('+'), onPressed: (){
        showNotification();
      },),
      appBar: AppBar(
        title:Text('Instagram'),
        actions: [
          IconButton(
            icon:Icon(Icons.add_box_outlined),
            onPressed: () async {
              var picker = ImagePicker();
              var image = await picker.pickImage(source:ImageSource.gallery);
              if (image!=null){
                setState(() {
                  userImage = File(image.path);
                });}

              Navigator.push(context,
                MaterialPageRoute(builder: (c)=> Upload(
                    userImage:userImage, setUserContent: setUserContent,
                    addMyData:addMyData)));
            },),
        ],
      ),
      body:[Home(state:urlData, addData:addMyData), Shop()][tab],

      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,

        onTap: (i){
          setState(() {
              tab=i;
            });
          },

        items: [
          BottomNavigationBarItem(icon:Icon(Icons.home_outlined),label:'홈'),
          BottomNavigationBarItem(icon:Icon(Icons.shopping_bag_outlined), label:'샵'),
      ]),
    );
  }
}//myApp 끝났음


class Home extends StatefulWidget {
  Home({Key? key, this.state, this.addData}) : super(key:key);
  final state;
  final addData;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var scroll = ScrollController();

  getNewData() async {
    var newData = await http.get(Uri.parse('https://codingapple1.github.io/app/more1.json'));
    setState(() {
      widget.state.add(jsonDecode(newData.body));
    });
  }

  @override
  void initState() {
    super.initState();
    scroll.addListener((){
      if(scroll.position.pixels==scroll.position.maxScrollExtent){
        getNewData();
      }
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    if(widget.state.isNotEmpty){
      return  ListView.builder(itemCount:widget.state.length,controller:scroll,itemBuilder:(c,i)
      {
        return Column(
          children:[
            SizedBox(
              width:double.infinity,
              child:
              Column(
                  children: [
                    widget.state[i]['image'].runtimeType==String
                      ?Image.network(widget.state[i]['image'] ,width: double.infinity,
            fit: BoxFit.cover)
                      :Image.file(widget.state[i]['image'] ,width: double.infinity,
            fit: BoxFit.cover),



                    Container(
                      padding: EdgeInsets.all(20),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('좋아요 ${widget.state[i]['likes']}'),
                          GestureDetector(
                              child: Text('글쓴이 ${widget.state[i]['user']}'),
                              onTap:(){
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (c)=>Profile()));
                              }
                          ),
                          Text(widget.state[i]['date']),
                          Text('글내용 ${widget.state[i]['content']}'),],
                      )
                    )
                  ],
              ),
            ),
          ],
      );
    },
        );}else{
      return Text('로딩중임');
    }
  }
}

class Upload extends StatelessWidget {
  Upload({Key? key, this.userImage, this.setUserContent, this.addMyData}) : super(key:key);
  final userImage;
  final setUserContent;
  final addMyData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:true,
      appBar: AppBar(
        actions:[IconButton(onPressed: (){
          addMyData();
          Navigator.pop(context);
        }, icon: Icon(Icons.send))]
      ),
      body:SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(userImage),
            TextField(
              onChanged: (text)
              {setUserContent(text);}
            ),
            Text('이미지 업로드 화면'),
            IconButton(onPressed: (){
              Navigator.pop(context);
            }, icon: Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text(context.watch<Store2>().name)),
      body:CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child:ProfileHeader(),
          ),
          SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (c,i)=>Image.network(
                  context.watch<Store1>().profileImage[i],
                  fit: BoxFit.cover),
              childCount:context.watch<Store1>().profileImage.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2))
        ],
      )
    );
  }
}


class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Icon(Icons.circle, color: Colors.grey,),
        Text('팔로워 ${context.watch<Store1>().follow}명'),
        ElevatedButton(onPressed: (){
          context.read<Store1>().addFollow();
        }, child: Text('팔로우')),
        ElevatedButton(onPressed:(){
          context.read<Store1>().getData();
        },
            child: Text('이미지 가져오기'))
      ],
    );
  }
}

