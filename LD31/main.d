import EncoShared;
import EncoDesktop;
import EncoGL3;

import GameScene;

import std.stdio;
import std.traits;

class Timer
{
	int startTicks;

	int pausedTicks;

	bool paused;
	bool started;

	this()
	{
		startTicks = 0;
		pausedTicks = 0;
		paused = false;
		started = false;
	}

	//The various clock actions
	void start()
	{
		started = true;

		paused = false;

		startTicks = SDL_GetTicks();
	}
	void stop()
	{
		started = false;

		paused = false;
	}
	void pause()
	{
		if(started && !paused)
		{
			paused = true;
			pausedTicks = SDL_GetTicks() - startTicks;
		}
	}
	void unpause()
	{
		if(paused)
		{
			paused = false;
			startTicks = SDL_GetTicks() - pausedTicks;
			pausedTicks = 0;
		}
	}

	int get_ticks()
	{
		if(started)
		{
			if(paused)
			{
				return pausedTicks;
			}
			else
			{
				return SDL_GetTicks() - startTicks;
			}
		}

		return 0;
	}
}

void main() {
	auto renderer = new GL3Renderer();

	auto context = new EncoContext(
				new DesktopView("Ludum Dare 31 Game", 0, 0),
				renderer,
				new GameScene());
	context.start();
	renderer.setClearColor(121 / 255.0f, 85 / 255.0f, 72 / 255.0f);

	Camera camera = new Camera();
	camera.setWidth(1600);
	camera.setHeight(900);
	camera.setFarClip(1000.0f);
	camera.setFov(90);

	camera.transform.position = vec3(-5, 120, -5);
	camera.transform.rotation = vec3(-1.57079633f, 0, 0);

	RenderContext render = RenderContext();
	render.camera = camera;

	Timer fps = new Timer();

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glEnable(GL_DEPTH_TEST);
	//glEnable(GL_CULL_FACE);
	//glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

	const int FRAMES_PER_SECOND = 60;

	KeyboardState* state = Keyboard.getState();

	while(context.update())
	{
		state = Keyboard.getState();

		renderer.beginFrame();
		renderer.clearBuffer(RenderingBuffer.colorBuffer | RenderingBuffer.depthBuffer);

		context.draw(render);

		renderer.endFrame();

		if (state.isKeyDown(SDLK_ESCAPE)) break;

		if(fps.get_ticks() < 1000 / FRAMES_PER_SECOND)
		{
			SDL_Delay(1000 / FRAMES_PER_SECOND - fps.get_ticks());
		}

	}

	context.stop();
}
