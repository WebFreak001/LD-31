import EncoShared;
import EncoDesktop;
import EncoGL3;

import GameScene;

import std.stdio;
import std.traits;

void main() {
	auto renderer = new GL3Renderer();

	auto context = new EncoContext(
				new DesktopView("Ludum Dare 31 Game", 0, 0),
				renderer,
				new GameScene());
	context.start();
	renderer.setClearColor(0.5f, 0.8f, 1.0f);

	Camera camera = new Camera();
	camera.setWidth(1600);
	camera.setHeight(900);
	camera.setFarClip(1000.0f);
	camera.setFov(90);

	camera.transform.position = vec3(0, 120, 0);
	camera.transform.rotation = vec3(-1.57079633f, 0, 0);

	RenderContext render = RenderContext();
	render.camera = camera;

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glEnable(GL_DEPTH_TEST);
	//glEnable(GL_CULL_FACE);
	//glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

	// TODO: Minimize all this code to 15-25 lines + shaders + imports

	KeyboardState* state = Keyboard.getState();
	MouseState* mstate = Mouse.getState();

	while(context.update())
	{
		state = Keyboard.getState();
		mstate = Mouse.getState();

		renderer.beginFrame();
		renderer.clearBuffer(RenderingBuffer.colorBuffer | RenderingBuffer.depthBuffer);

		context.draw(render);

		renderer.endFrame();

		if (state.isKeyDown(SDLK_ESCAPE)) break;
	}

	context.stop();
}
