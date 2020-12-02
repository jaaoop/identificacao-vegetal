import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:identificador_plantas/helpers/database_helper.dart';
import 'package:identificador_plantas/planta_identificada.dart';

import 'historico.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttericon/elusive_icons.dart';

///A classe CameraScreen é a tela inicial do aplicativo.
///Nela estão presentes a Camera, o Botão de reconhecimento de planta e o botão de histórico.
///Seus métodos são privados, deve funcionar como um Widget sem parâmetros.
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State {
  CameraController controller;
  List cameras;
  int selectedCameraIndex;
  String imgPath;
  final dbHelper = DatabaseHelper.instance;

  /// função de inicio do Widget, checa se existem cameras para usar e as requisita para uso, caso não seja possível, gera um erro.
  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        _initCameraController(cameras[selectedCameraIndex]).then((void v) {});
      } else {
        print('No camera available');
      }
    }).catchError((err) {
      print('Error :${err.code}Error message : ${err.message}');
    });
  }

  ///Inicia o controlador da Câmera, adiconando o listener a ele e setando a resolução desejada
  /// CameraDescription cameraDescription
  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  ///Método build da classe, retorna a tela desejada com a Camera e os botões.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              //Camera
              Expanded(
                flex: 1,
                child: _cameraPreviewWidget(),
              ),
              //Barra verde de baixo da camera
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.lightGreen[900],
                  //Botões
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      //botão de historico
                      _historyButton(context),
                      //botão de identificação
                      _cameraControlWidget(context),
                      Spacer()
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Widget que mostra o preview da Camera
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  /// Mostra a barra de controle com o botão de reconhecimento de planta
  Widget _cameraControlWidget(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              child: Icon(
                Elusive.leaf,
                color: Colors.lightGreen[900],
              ),
              backgroundColor: Colors.white,
              onPressed: () {
                //invoca a função de reconhecimento de planta e muda de página
                _onCapturePressed(context);
              },
            )
          ],
        ),
      ),
    );
  }

  ///Botão do histórico de observações
  Widget _historyButton(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
                width: 125,
                height: 125,
                child: IconButton(
                  icon: Icon(
                    Icons.history,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    //abre tela de histórico
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Historico()),
                    );
                  },
                ))
          ],
        ),
      ),
    );
  }

  /// mostra exceções e erros gerados pela camera
  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  /// Função responsável por tirar a foto, salvar, cortar e redimensionar para por na rede neural e muda para a página de acordo com o resultado
  void _onCapturePressed(context) async {
    try {
      //salva a imagem num diretorio temporário
      final path =
          join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      await controller.takePicture(path);

      //TODO: crop e resize na imagem para dimensões da rede neural

      //TODO: usar rede neural

      //guarda a observação feita no histórico
      await dbHelper.insertObservacao(3);
      //vai para a página da observação encontrada
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Identificada(idPlanta: 3, porcentagem: 0.75)),
      );
    } catch (e) {
      print(e);
    }
  }
}
