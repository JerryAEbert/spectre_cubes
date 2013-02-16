import 'dart:html';
import 'dart:math';
import 'package:vector_math/vector_math.dart';
import 'package:game_loop/game_loop.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:spectre/spectre.dart';
import 'package:spectre/spectre_asset_pack.dart';

final String _canvasId = '#backbuffer';

GraphicsDevice _graphicsDevice;
GraphicsContext _graphicsContext;
DebugDrawManager _debugDrawManager;

GameLoop _gameLoop;
AssetManager _assetManager;


Viewport _viewport;
final Camera camera = new Camera();
final cameraController = new MouseKeyboardCameraController();
double _lastTime;
bool _circleDrawn = false;

/* Skybox */
SingleArrayIndexedMesh _skyboxMesh;
ShaderProgram _skyboxShaderProgram;
InputLayout _skyboxInputLayout;
SamplerState _skyboxSampler;
DepthState _skyboxDepthState;
BlendState _skyboxBlendState;
RasterizerState _skyboxRasterizerState;

Float32Array _cameraTransform = new Float32Array(16);
List<Cube> cubes = new List<Cube>();

class Cube {
  SingleArrayIndexedMesh _unitCubeMesh;
  InputLayout _unitCubeInputLayout;
  ShaderProgram _unitCubeShaderProgram;
  RasterizerState _unitCubeRasterizerState;
  DepthState _unitCubeDepthState;
  Texture2D _unitCubeTexture;
  GraphicsDevice graphicsDevice;
  vec3 translation;
  mat4 modelMatrix;
  int height;
  int width;
  num depth; // shoudl be double

  /// View matrix for the application.
  //mat4 _viewMatrix;
  /// Projection matrix.
  //mat4 _projectionMatrix;
  /// View-Projection matrix.
  mat4 _viewProjectionMatrix;
  /// Model-view-projection matrix.
  mat4 _modelViewProjectionMatrix;
  /// Array containing the model-view-projection matrix.
  Float32Array _modelViewProjectionMatrixArray = new Float32Array(16);
  Float32Array _modelMatrixArray = new Float32Array(16);

  Cube(this.graphicsDevice, this.translation, this.width, this.height, this.depth, List<int> color) {
    //translation.setComponents(translation.x * 0.1, translation.y * 0.1, translation.z);
    //_viewMatrix = new mat4.identity();
    //_projectionMatrix = new mat4.identity();


    _unitCubeShaderProgram = _assetManager.root.demoAssets.litdiffuse;
    _unitCubeMesh = _assetManager.root.demoAssets.unitCube;

    _unitCubeTexture = new Texture2D("unitCubeTexture", graphicsDevice);
    _unitCubeTexture.uploadPixelArray(1, 1, new Uint8Array.fromList(color), pixelFormat: SpectreTexture.FormatRGBA, pixelType: SpectreTexture.PixelTypeU8);

    _unitCubeInputLayout = new InputLayout('${translation.toString()}-unitCube.il', graphicsDevice);
    _unitCubeInputLayout.mesh = _unitCubeMesh;
    _unitCubeInputLayout.shaderProgram = _unitCubeShaderProgram;

    _unitCubeRasterizerState = new RasterizerState('${translation.toString()}-unitCube.rs', graphicsDevice);
    _unitCubeRasterizerState.cullMode = CullMode.Back;

    _unitCubeDepthState = new DepthState('${translation.toString()}-unitCube.ds', graphicsDevice);
    _unitCubeDepthState.depthBufferEnabled = true;
    _unitCubeDepthState.depthBufferWriteEnabled = true;
    _unitCubeDepthState.depthBufferFunction = CompareFunction.LessEqual;

  }

  drawCube() {
    var context = graphicsDevice.context;
    context.setPrimitiveTopology(GraphicsContext.PrimitiveTopologyTriangles);
    context.setShaderProgram(_unitCubeShaderProgram);
    context.setTextures(0, [_unitCubeTexture]);
    context.setSamplers(0, [_skyboxSampler]);


//    mat4 P = camera.projectionMatrix;
//    mat4 LA = camera.lookAtMatrix;
//
//    P.multiply(LA);
//
//    P.copyIntoArray(_cameraTransform, 0);

    _viewProjectionMatrix = new mat4.identity();
    _modelViewProjectionMatrix = new mat4.identity();
    modelMatrix = new mat4.identity();
    //modelMatrix.setTranslation(translation);
    //modelMatrix.scale(width * 1.0, height * 1.0);

    _viewProjectionMatrix.copyFrom(camera.lookAtMatrix);
    _viewProjectionMatrix.multiply(camera.projectionMatrix);
    _viewProjectionMatrix.copyIntoArray(_cameraTransform, 0);
//    _modelViewProjectionMatrix.copyFrom(_viewProjectionMatrix);
//    _modelViewProjectionMatrix.multiply(modelMatrix);
//    _modelViewProjectionMatrix.copyIntoArray(_modelViewProjectionMatrixArray);
    modelMatrix.copyIntoArray(_modelMatrixArray);
    context.setConstant('objectTransform', _modelMatrixArray);
    context.setConstant('cameraTransform', _cameraTransform);


    context.setBlendState(_skyboxBlendState);
    context.setRasterizerState(_unitCubeRasterizerState);
    context.setDepthState(_unitCubeDepthState);
    context.setInputLayout(_unitCubeInputLayout);

    context.setIndexedMesh(_unitCubeMesh);
    context.drawIndexedMesh(_unitCubeMesh);
  }
}

_setupCubes() {
  cubes.add(new Cube(_graphicsDevice, new vec3(0.0,  -2.0,  -1.0), 21,  14,   3, [0x22, 0x22, 0x22, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(1.0,  -1.0,  -1.0), 19,  16,   3, [0x22, 0x22, 0x22, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(2.0,   0.0,  -1.0), 17,  18,   3, [0x22, 0x22, 0x22, 0xff]));

  cubes.add(new Cube(_graphicsDevice, new vec3(1,  -2,-1.5),  19,  14,   4, [0xff, 0xcc, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(2,  -1,-1.5),  17,  16,   4, [0xff, 0xcc, 0x99, 0xff]));

  cubes.add(new Cube(_graphicsDevice, new vec3(2,  -4,   2),  17,  10,  .6, [0xff, 0x99, 0xff, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(3,  -3,   2),  15,  12,  .6, [0xff, 0x99, 0xff, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(4,  -2,   2),  13,  14,  .6, [0xff, 0x99, 0xff, 0xff]));

  cubes.add(new Cube(_graphicsDevice, new vec3(4,  -4,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(9,  -3,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(12,  -3,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(16,  -5,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(8,  -7,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(5,  -9,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(9, -10,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(3, -11,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(7, -13,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
  cubes.add(new Cube(_graphicsDevice, new vec3(4, -14,   2),   1,   1,  .7, [0xff, 0x33, 0x99, 0xff]));
}

_drawCubes() {
  cubes.forEach((c) => c.drawCube());
}

void gameFrame(GameLoop gameLoop) {
  double dt = gameLoop.dt;
  cameraController.forwardVelocity = 25.0;
  cameraController.strafeVelocity = 25.0;
  cameraController.forward =
      gameLoop.keyboard.buttons[GameLoopKeyboard.W].down;
  cameraController.backward =
      gameLoop.keyboard.buttons[GameLoopKeyboard.S].down;
  cameraController.strafeLeft =
      gameLoop.keyboard.buttons[GameLoopKeyboard.A].down;
  cameraController.strafeRight =
      gameLoop.keyboard.buttons[GameLoopKeyboard.D].down;
  if (gameLoop.pointerLock.locked) {
    cameraController.accumDX = gameLoop.mouse.dx;
    cameraController.accumDY = gameLoop.mouse.dy;
  }

  cameraController.UpdateCamera(gameLoop.dt, camera);
  // Update the debug draw manager state
  _debugDrawManager.update(dt);
}

void renderFrame(GameLoop gameLoop) {
  // Clear the color buffer
  _graphicsContext.clearColorBuffer(0.0, 0.0, 0.0, 1.0);
  // Clear the depth buffer
  _graphicsContext.clearDepthBuffer(1.0);
  // Reset the context
  _graphicsContext.reset();
  // Set the viewport
  _graphicsContext.setViewport(_viewport);
  // Add three lines, one for each axis.
  _debugDrawManager.addLine(new vec3.raw(0.0, 0.0, 0.0),
                            new vec3.raw(100.0, 0.0, 0.0),
                            new vec4.raw(1.0, 0.0, 0.0, 1.0));
  _debugDrawManager.addLine(new vec3.raw(0.0, 0.0, 0.0),
                            new vec3.raw(0.0, 100.0, 0.0),
                            new vec4.raw(0.0, 1.0, 0.0, 1.0));
  _debugDrawManager.addLine(new vec3.raw(0.0, 0.0, 0.0),
                            new vec3.raw(0.0, 0.0, 100.0),
                            new vec4.raw(0.0, 0.0, 1.0, 1.0));
  if (_circleDrawn == false) {
    _circleDrawn = true;
    // Draw a circle that lasts for 5 seconds.
    _debugDrawManager.addCircle(new vec3.raw(0.0, 0.0, 0.0),
                                new vec3.raw(0.0, 1.0, 0.0),
                                2.0,
                                new vec4.raw(1.0, 1.0, 1.0, 1.0),
                                5.0);
  }

  _drawSkybox();
  _drawCubes();
  // Prepare the debug draw manager for rendering
  _debugDrawManager.prepareForRender();
  // Render it
  _debugDrawManager.render(camera);
}

// Handle resizes
void resizeFrame(GameLoop gameLoop) {
  CanvasElement canvas = gameLoop.element;
  // Set the canvas width and height to match the dom elements
  canvas.width = canvas.clientWidth;
  canvas.height = canvas.clientHeight;
  // Adjust the viewport dimensions
  _viewport.width = canvas.width;
  _viewport.height = canvas.height;
  // Fix the camera's aspect ratio
  camera.aspectRatio = canvas.width.toDouble()/canvas.height.toDouble();
}

void _setupSkybox() {
  _skyboxShaderProgram = _assetManager.root.demoAssets.skyBoxShader;
  assert(_skyboxShaderProgram.linked == true);
  _skyboxMesh = _assetManager.root.demoAssets.skyBox;
  _skyboxInputLayout = new InputLayout('skybox.il', _graphicsDevice);
  _skyboxInputLayout.mesh = _skyboxMesh;
  _skyboxInputLayout.shaderProgram = _skyboxShaderProgram;

  assert(_skyboxInputLayout.ready == true);
  _skyboxSampler = new SamplerState('skybox.ss', _graphicsDevice);
  _skyboxDepthState = new DepthState('skybox.ds', _graphicsDevice);
  _skyboxBlendState = new BlendState('skybox.bs', _graphicsDevice);
  _skyboxBlendState.enabled = false;
  _skyboxRasterizerState = new RasterizerState('skybox.rs', _graphicsDevice);
  _skyboxRasterizerState.cullMode = CullMode.None;
}

void _drawSkybox() {
  var context = _graphicsDevice.context;
  context.setInputLayout(_skyboxInputLayout);
  context.setPrimitiveTopology(GraphicsContext.PrimitiveTopologyTriangles);
  context.setShaderProgram(_skyboxShaderProgram);
  context.setTextures(0, [_assetManager.root.demoAssets.space]);
  context.setSamplers(0, [_skyboxSampler]);
  {
    mat4 P = camera.projectionMatrix;
    mat4 LA = makeLookAt(new vec3.zero(),
        camera.frontDirection,
        new vec3(0.0, 1.0, 0.0));
    P.multiply(LA);
    P.copyIntoArray(_cameraTransform, 0);
  }
  context.setConstant('cameraTransform', _cameraTransform);
  context.setBlendState(_skyboxBlendState);
  context.setRasterizerState(_skyboxRasterizerState);
  context.setDepthState(_skyboxDepthState);
  context.setIndexedMesh(_skyboxMesh);
  context.drawIndexedMesh(_skyboxMesh);
}

void main() {

  // TODO(adam): must be a better way to get base url from location.
  final String baseUrl = "${window.location.href.substring(0, window.location.href.length - "spectre_cubes.html".length)}";
  print(baseUrl);
  CanvasElement canvas = query(_canvasId);
  assert(canvas != null);


  // Create a GraphicsDevice
  _graphicsDevice = new GraphicsDevice(canvas);
  // Print out GraphicsDeviceCapabilities
  print(_graphicsDevice.capabilities);
  // Get a reference to the GraphicsContext
  _graphicsContext = _graphicsDevice.context;
  // Create a debug draw manager and initialize it
  _debugDrawManager = new DebugDrawManager(_graphicsDevice);

  // Set the canvas width and height to match the dom elements
  canvas.width = canvas.clientWidth;
  canvas.height = canvas.clientHeight;

  // Create the viewport
  _viewport = new Viewport('view', _graphicsDevice);
  _viewport.x = 0;
  _viewport.y = 0;
  _viewport.width = canvas.width;
  _viewport.height = canvas.height;

  // Create the camera
  camera.aspectRatio = canvas.width.toDouble()/canvas.height.toDouble();
  camera.position = new vec3.raw(2.0, 2.0, 2.0);
  camera.focusPosition = new vec3.raw(1.0, 1.0, 1.0);

  _assetManager = new AssetManager();
  registerSpectreWithAssetManager(_graphicsDevice, _assetManager);

  _gameLoop = new GameLoop(canvas);
  _gameLoop.onUpdate = gameFrame;
  _gameLoop.onRender = renderFrame;
  _gameLoop.onResize = resizeFrame;
  _assetManager.loadPack('demoAssets', '$baseUrl/assets.pack').then((assetPack) {
    // All assets are loaded.
    _setupSkybox();
    _setupCubes();

    _gameLoop.start();
  });
}

