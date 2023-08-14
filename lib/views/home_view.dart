import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';





class HomeView extends StatefulWidget {
  final CameraDescription camera;

  const HomeView({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

enum VibrationDuration {
  start,
  end,
}

class _HomeViewState extends State<HomeView> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  FlutterTts flutterTts = FlutterTts();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String ?_text;
  bool speaking = false;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  late AudioPlayer _audioPlayer;
  late AudioCache audioCache;
  String url = "http://192.168.1.9:5000/";
  String ?endpoint;
  String ?recentOutputTxt;
  int model = 0;
  String ?_deviceToken;
  bool _isFirstRun = true;
  bool addFriend = false;
  bool firstTap = true;
  // FlutterSoundRecorder? _audioRecorder = FlutterSoundRecorder();
  String introduction = "Hello! I'm your helpful 'Vision' app, here to assist you throughout your day. Let me quickly explain how to use me.\n"
      "First, you can skip or stop me from talking by simply double-tapping on the screen.\n"
      "Second, you can switch between different modes by swiping left or right, or by using specific voice commands. Once you reach the desired mode, double-tap on the screen to start using it.\n"
      "And third, to use your voice, just long-press on the screen, and I'll start recording.\n"
      "Now, let me introduce you to the different modes available:\n"
      "- Find Objects: This mode is always active. Just use your voice to tell me what you're looking for, and I'll let you know if it's nearby or not found.\n"
      "- Describe the Surroundings: Activate this mode by saying 'Describe.' It's used to describe the scene in front of you.\n"
      "- Money Calculator: Say 'Money' to activate this mode. It helps you recognize and count Egyptian currency.\n"
      "- Face Recognition: Say 'Face' to activate this mode. It allows you to recognize your friends' faces. If I spot someone new, you can add them to your friends list by saying his name\n"
      "- Reading Mode: Activate this mode by saying 'Read.' It's used for text recognition.\n"
      "If you ever need to hear this introduction again, just say 'Introduction.' Enjoy using the app, and have a fantastic day!";

  // final String intro = "How are you my friend, I'm 'Vision' App, glad to help you throughout your day, let me tell you"
  //     "briefly how to use me. First, to skip the introduction or to stop me whenever I'm talking just double tap"
  //     "on the screen. Second, to switch between different modes you can just swipe left, right or use certain"
  //     "voice commands, when you reach the mode you want just double tap on the screen to start using it."
  //     "Third, whenever you want to use your voice you just need to long tap on the screen and I will start recording."
  //     "Now let me tell you more about the modes you can use, they are 5 different modes."
  //     "First one is find objects mode, this mode is already activated all the time, no need to double tap or swipe left"
  //     "or right to reach it, you only use a long tap to use your voice and tell me what you are looking for and I"
  //     "will tell you if it's far, close, or even not found around you. Second one is Describe the surroundings mode,"
  //     "to activate this mode by voice command just say Describe, it's used to describe the scene in front of you."
  //     "Third one is Money calculator mode, to activate this mode by voice command just say money, it's used to"
  //     "recognize and count Egyptian currency. Fourth one is Face recognition mode, to activate this mode by voice"
  //     "command just say Face, it's used to recognize your friends' faces, if I see someone new you have the option"
  //     "to add him to your friends list by saying add. The last one is reading mode, to activate this mode by voice command just"
  //     "say Read. If you need to hear this how to use intro again just say introduction, and that's it, have a nice day";
  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    _getDeviceToken();
    _audioPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: _audioPlayer);
    audioCache.load('sounds/start_record.mp3');
    // audioCache.load('sounds/end_record.mp3');
    _checkFirstRun();
    endpoint = "${url}detect";
  }

  @override
  void dispose() {
    _controller.dispose();
    // _audioRecorder = null;
    super.dispose();
  }


  // Future<void> _startRecording() async {
  //   audioCache.play('sounds/start_record.mp3');
  //   await _audioRecorder!.startRecorder(
  //     toFile: 'assets/sounds/records/moneyRec1.wav',
  //     codec: Codec.pcm16WAV,
  //   );
  // }

  // Future<void> _stopRecordingAndProcess() async {
  //   await _audioRecorder!.stopRecorder();
  //   // Retrieve the audio file path and send it to the TFLite model for processing
  //   String audioFilePath = 'assets/sounds/records/moneyRec1.wav';
  //   await _processAudioPrediction(audioFilePath);
  //
  // }


  // Future<void> _processAudioPrediction(String audioFilePath) async {
  //   // Load the TFLite model
  //   final interpreter = await tfl.Interpreter.fromAsset('assets/your_model.tflite');
  //   var output;
  //   interpreter.run(audioFilePath, output);
  //   print(output);
  // }

  Future<void> _getDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    setState(() {
      _deviceToken = token;
    });
    print(_deviceToken);
  }

  Future<void> sendTextToServer(String txt) async {
    var request = http.MultipartRequest('POST', Uri.parse(endpoint!));
    request.fields['text'] = txt;
    await request.send().timeout(const Duration(seconds: 40));
  }

  Future<void> translateOutput(txt) async{
    String localEndpoint = '${url}trans';
    var request = http.MultipartRequest('POST', Uri.parse(localEndpoint));
    request.fields['text'] = txt;
    displayResponse(request, true);
  }

  Future<void> _checkFirstRun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;
    if (isFirstRun) {
      await prefs.setBool('isFirstRun', false);
      // Function to run only once
      endpoint = "${url}new_user";
      //send token to the server to create new user
      sendTextToServer(_deviceToken!);
      _displayVoiceOutput(introduction, false);
    }
    else{
      _displayVoiceOutput("Hello my friend! how can I help you", false);
    }
    setState(() {
      _isFirstRun = false;
    });
  }

  Future<void> _displayVoiceOutput(String txt, bool arabic) async {
    speaking = true;
    if(arabic){
      flutterTts.setLanguage('ar');

    }
    else{
      flutterTts.setLanguage('en');
    }
    recentOutputTxt = txt;
    await flutterTts.getVoices;
    await flutterTts.speak(txt);
    flutterTts.completionHandler = () {
      setState(() {
        speaking = false;
      });
    };
  }

  Future<Uint8List> _captureFrame() async {
    XFile imageFile = await _controller.takePicture();
    File file = File(imageFile.path);
    final bytes = await file.readAsBytes();
    return bytes;
  }

  Future<MultipartRequest> _imageReq() async {
    final bytes = await _captureFrame();
    var request = http.MultipartRequest('POST', Uri.parse(endpoint!));
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'image.jpg',
      ),
    );
    return request;
  }

  Future<void> displayResponse(MultipartRequest request, bool arabic) async {
    var response = await request.send().timeout(const Duration(seconds: 40));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(await response.stream.bytesToString());

      _displayVoiceOutput(responseData['text'], arabic);
      if(responseData['text'] == "New face has been detected"){
        addFriend = true;
        // _displayVoiceOutput("If you want to add him to your friends list say his name or just say skip", false);

      }
    }
    else {
      throw Exception('Failed to load response');
    }
  }

  Future<void> _onDoubleTap() async {
    addFriend = false;
    if (speaking == true) {
      await flutterTts.stop();
      speaking = false;
    }
    else if (_controller.value.isInitialized) {
      try {
        var request = await _imageReq();
        if(endpoint == "${url}face"){
          request.fields['text'] = _deviceToken!;
          _displayVoiceOutput("let's see who's here", false);
        }
        else if(endpoint == "${url}money"){
          _displayVoiceOutput("counting money", false);
        }
        else if(endpoint == "${url}caption"){
          _displayVoiceOutput("give me a second to recognize the scene in front of you", false);
        }
        else if(endpoint == "${url}ocr"){
          _displayVoiceOutput("reading", false);
        }
        await displayResponse(request, false);
      }
      catch (e) {
        print('Error: $e');
      }
    }
  }

  void swipLeftOrRight(DragEndDetails details){
    // the order of models
    //img captioning 0, money recognition 1,
    //face recognition 2, ocr 3
    addFriend = false;
    if (details.primaryVelocity! < 0.1) {
      // Right Swipe
      model = (model + 1) % 4;
      print(model);
    }
    else if(details.primaryVelocity! > 0.1){
      //Left Swipe
      model = (model - 1) % 5;
      print(model);

    }

    if(details.primaryVelocity! != 0.1){
      switch(model) {
        case 0: {
          endpoint = "${url}caption";
          _displayVoiceOutput("Describe the surroundings mode", false);
        }
        break;
        case 1: {
          endpoint = "${url}money";
          _displayVoiceOutput("Money calculator mode", false);
        }
        break;
        case 2: {
          endpoint = "${url}face";
          _displayVoiceOutput("Face recognition mode", false);
        }
        break;
        case 3: {
          endpoint = "${url}ocr";
          _displayVoiceOutput("Reading mode", false);
        }
        break;
      }
    }

  }

  Future<void> _listen() async {
    if (!speaking && await _speechToText.initialize()) {
      audioCache.play('sounds/start_record.mp3');
      _speechToText.listen(
        onResult: (result) async {
          if (result.recognizedWords!= "") {
            _text = result.recognizedWords;
          }
        },
      );
    }
  }


  Future<void> onLongPressStart(LongPressStartDetails details) async {
    _text = "";
    await _listen();
    // await _startRecording();
  }

  Future<void> onLongPressEnd(LongPressEndDetails details) async {
    // await _stopRecordingAndProcess();
    _speechToText.stop();
    // await audioCache.play('sounds/end_record.mp3');
    _processInputTxt(_text!);
  }

  Future<void> _processInputTxt(String inputTxt) async {
    //the input could be voice command or object that the user is searching for
    //or name of a friend to be added
    if(addFriend == true && endpoint == '${url}face'){
      addFriend = false;
      if(!inputTxt.contains('skip')){
        endpoint = "${url}face/add_friend";
        var request = http.MultipartRequest('POST', Uri.parse(endpoint!));
        request.fields['text'] = "$inputTxt ${_deviceToken!}";
        await displayResponse(request, false);
      }
    }
    else{
      if(inputTxt == ''){
        // endpoint = "${url}money";
        // _displayVoiceOutput("Money calculator mode", false);
      }
      else if(inputTxt.contains('money')){
        endpoint = "${url}money";
        _displayVoiceOutput("Money calculator mode", false);
      }
      else if(inputTxt.contains('describe')){
        endpoint = "${url}caption";
        _displayVoiceOutput("Describe the surroundings mode", false);
      }
      else if(inputTxt.contains('face')){
        endpoint = "${url}face";
        _displayVoiceOutput("Face recognition mode", false);
      }
      else if(inputTxt.contains('read')){
        endpoint = "${url}ocr";
        _displayVoiceOutput("Reading mode", false);
      }
      else if(inputTxt.contains('introduction')){
        _displayVoiceOutput(introduction, false);
      }
      else if(inputTxt.contains('Arabi') || inputTxt.contains('Translate')){
        translateOutput(recentOutputTxt);
      }
      else if(inputTxt.contains('flos')){
        endpoint = "${url}money";
        _displayVoiceOutput("تم تفعيل نظام التعرف علي العملات النقدية", true);
      }
      else{
        endpoint = "${url}detect";
        try {
          var request = await _imageReq();
          request.fields['text'] = inputTxt;
          _displayVoiceOutput('looking for $inputTxt', false);
          await displayResponse(request, false);
          // setState(() {
          //   _text = "";
          // });

        } catch (e) {
          print('Error: $e');
        }
      }

    //   else{
    //   switch(inputTxt) {
    //     case "": {
    //       if(!firstTap) {
    //         firstTap = false;
    //         _displayVoiceOutput("Sorry I can not hear you", false);
    //       }
    //     }
    //     break;
    //     case 'describe': {
    //       endpoint = "${url}caption";
    //       _displayVoiceOutput("Describe the surroundings mode", false);
    //     }
    //     break;
    //     case 'money': {
    //       endpoint = "${url}money";
    //       _displayVoiceOutput("Money calculator mode", false);
    //     }
    //     break;
    //     case 'flos': {
    //       endpoint = "${url}money";
    //       _displayVoiceOutput("تم تفعيل نظام التعرف علي العملات النقدية", true);
    //     }
    //     break;
    //     case 'face': {
    //       endpoint = "${url}face";
    //       _displayVoiceOutput("Face recognition mode", false);
    //     }
    //     break;
    //     case 'read': {
    //       endpoint = "${url}ocr";
    //       _displayVoiceOutput("Reading mode", false);
    //     }
    //     break;
    //     case 'introduction': {
    //       _displayVoiceOutput(introduction, false);
    //     }
    //     break;
    //     case 'Arabi': {
    //       translateOutput(recentOutputTxt);
    //     }
    //     break;
    //     default:
    //       endpoint = "${url}detect";
    //       try {
    //         var request = await _imageReq();
    //         request.fields['text'] = inputTxt;
    //         _displayVoiceOutput('looking for $inputTxt', false);
    //         await displayResponse(request, false);
    //         // setState(() {
    //         //   _text = "";
    //         // });
    //
    //       } catch (e) {
    //         print('Error: $e');
    //       }
    //   }
    // }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Smart Visionary App"),
        backgroundColor: Colors.black,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: GestureDetector(
          onLongPressStart: onLongPressStart,
          onHorizontalDragEnd: swipLeftOrRight,
          onLongPressEnd: onLongPressEnd,
          onDoubleTap: _onDoubleTap,
          child: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}