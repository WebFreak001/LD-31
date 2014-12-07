module GameScene;

import EncoShared;
import EncoDesktop;
import EncoGL3;

import std.stdio;
import std.algorithm;

import Level;
import NoDepthComponent;
import ParticleSystem;
import AStar;

enum MAT_HOUSEL1 = 0;
enum MAT_TRAILER1 = 1;
enum MAT_STONE = 2;
enum MAT_STREET = 3;
enum MAT_ERROR = 4;

Mesh[] floor;
Mesh[] error;
Mesh[] stone;
Mesh[] street;
Mesh[] houses_low;
Mesh[] ui;
Mesh[] car;
Mesh[] smoke;
Mesh[][string] meshes;
Material[string] materials;

MouseState* mouse;
KeyboardState* keyboard;
bool wasDown;
int cTool;

class Game3DLayer : RenderLayer
{
	Random random;
	Scene scene;

	MeshObject hover;
	Level level;

	u32vec2[] destroyQuery;

	u32vec2 start;

	ParticleSystem system;

	Waypoint startP, endP;
	Waypoint[] points;

	AStar astar;

	override void init(Scene scene)
	{
		this.scene = scene;

		floor = Mesh.loadFromObj("meshes/floor.obj", 0);
		error = Mesh.loadFromObj("meshes/error.obj", 0);
		stone = Mesh.loadFromObj("meshes/stone.obj", 0);
		street = Mesh.loadFromObj("meshes/street.obj", 0);
		houses_low = Mesh.loadFromObj("meshes/houses_low.obj", 0);
		ui = Mesh.loadFromObj("meshes/ui.obj", 0);
		car = Mesh.loadFromObj("meshes/car.obj", 0);
		smoke = Mesh.loadFromObj("meshes/smoke.obj", 0);
		
		meshes["floor"] = floor;
		meshes["stone"] = stone;
		meshes["street"] = street;
		meshes["houses_low"] = houses_low;
		meshes["ui"] = ui;
		meshes["car"] = car;
		meshes["smoke"] = smoke;

		materials = [
					"houseL1": GLMaterial.load(scene.renderer, "materials/houseL1.json"),
					"trailer1": GLMaterial.load(scene.renderer, "materials/trailer1.json"),
					"stone": GLMaterial.load(scene.renderer, "materials/stone.json"),
					"street": GLMaterial.load(scene.renderer, "materials/street.json"),
					"error": GLMaterial.load(scene.renderer, "materials/error.json"),
					"grass": GLMaterial.load(scene.renderer, "materials/grass.json"),
					"hover": GLMaterial.load(scene.renderer, "materials/hover.json"),
					"car": GLMaterial.load(scene.renderer, "materials/car.json"),
					"smoke": GLMaterial.load(scene.renderer, "materials/smoke.json"),
					];

		random = new Random();
		
		addMesh(floor[0], materials["grass"], vec3(-5, 0, -5));
		addStone(stone[1], materials["stone"], vec3(-110, 0, -20));
		addStone(stone[1], materials["stone"], vec3(-120, 0, -30));
		addStone(stone[0], materials["stone"], vec3(-130, 0, -10));
		addStone(stone[1], materials["stone"], vec3(-150, 0, -50));
		addStone(stone[1], materials["stone"], vec3(-200, 0, 10));
		addStone(stone[1], materials["stone"], vec3(-130, 0, 20));
		addStone(stone[1], materials["stone"], vec3(-140, 0, -30));
		
		for(int x = -40; x < -10; x++)
			addMesh(street[0], materials["street"], vec3(x * 10, 0, 0));

		hover = new MeshObject(ui[0], materials["hover"]);
		hover.transform.position = vec3(-10000, 0, -10000);
		hover.transform.rotation = vec3(0);
		hover.addComponent(new NoDepthComponent());

		system = new ParticleSystem();
		system.mesh = smoke[0];
		system.mat = materials["smoke"];
		system.addComponent(new NoDepthComponent());

		

		load("save0_auto");
	}

	private void load(string save)
	{
		level = new Level("saves/" ~ save ~ ".json");
		
		for(int i = 0; i < level.blocks.length; i++)
		{
			//if(level.blocks[i].type == BlockType.Residential)
			//	system.addEmitter(gridToAbsolute(vec3(level.blocks[i].position.x, 3, level.blocks[i].position.z)));
			addMesh(meshes[level.blocks[i].model][level.blocks[i].modelID], materials[level.blocks[i].material], gridToAbsolute(vec3(level.blocks[i].position.x, 0, level.blocks[i].position.z)), level.blocks[i].rotation * 0.0174532925f).data = cast(void*)1;
		}
	}

	private MeshObject addMesh(Mesh mesh, Material material, vec3 position, vec3 rotation = vec3(0))
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation = rotation;
		addGameObject(obj);
		return obj;
	}

	private void addTrailer(Mesh mesh, Material material, vec3 position)
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation.y = (random.nextFloat() - 0.5f) * 0.2f;
		addGameObject(obj);
	}

	private void addStone(Mesh mesh, Material material, vec3 position)
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation.y = (random.nextFloat() - 0.5f) * 3.1415926f;
		addGameObject(obj);
	}

	override protected void draw(RenderContext context, IRenderer renderer)
	{
		system.performDraw(context, renderer);
		hover.performDraw(context, renderer);

		const float gridX = 45 / 1920.0f;
		const float gridY = 45 / 1080.0f;
		
		const float gridStartX = 510 / 1920.0f;
		const float gridStartY = 90 / 1080.0f;

		u32vec2 v = scene.view.size;
		
		float mousePosX = mouse.position.x / cast(float)v.x;
		float mousePosY = mouse.position.y / cast(float)v.y;

		int x = cast(int)((mousePosX - gridStartX) / gridX);
		int y = cast(int)((mousePosY - gridStartY) / gridY);

		if(keyboard.isKeyDown(SDLK_LSHIFT) && cTool == 10000)
		{
			if(level.hasBlock(x, y))
			{
				auto sur = getSurronding(x, y, level.getBlock(x, y).type);
				foreach(u32vec2 block; sur)
				{
					hover.transform.position = gridToAbsolute(vec3(block.x, 0.5f, block.y));
					hover.performDraw(context, renderer);
				}
			}
		}

		if(points.length > 0)
		{
			foreach(Waypoint point; points)
			{
				hover.transform.position = gridToAbsolute(vec3(point.x, 0.5f, point.y));
				hover.performDraw(context, renderer);
			}
		}
	}
	

	override protected void update(f64 deltaTime)
	{
		level.update();

		if(mouse != null)
		wasDown = mouse.isButtonDown(0);
		mouse = Mouse.getState();

		keyboard = Keyboard.getState();

		const float gridX = 45 / 1920.0f;
		const float gridY = 45 / 1080.0f;
		
		const float gridStartX = 510 / 1920.0f;
		const float gridStartY = 90 / 1080.0f;

		u32vec2 v = scene.view.size;
		
		float mousePosX = mouse.position.x / cast(float)v.x;
		float mousePosY = mouse.position.y / cast(float)v.y;

		if(mousePosX > gridStartX && mousePosY > gridStartY && mousePosX < gridStartX + gridX * 20 && mousePosY < gridStartY + gridY * 20)
		{
			int x = cast(int)((mousePosX - gridStartX) / gridX);
			int y = cast(int)((mousePosY - gridStartY) / gridY);

			hover.transform.position = vec3((x - 10) * 10, 0, (y - 10) * 10);
			
			if(!wasDown && mouse.isButtonDown(0))
			{
				start = u32vec2(cast(u32)x, cast(u32)y);
			}

			if(mouse.isButtonDown(0))
			{
				if(cTool >= 0 && cTool <= 4)
				{
					switch(cTool)
					{
					case 0:
						if(!level.hasBlock(x, y))
						{
							auto mesh = addMesh(street[0], materials["street"], gridToAbsolute(vec3(x, 0, y)), vec3(0));
							mesh.data = cast(void*)1;
							Block block = level.postProcessStreet(level.add(&mesh, x, y, "street", 0, 0, "street", 0, BlockType.Street));
							level.blocks[level.blocks.length - 1] = block;
							level.updateStreets(x + 1, y);
							level.updateStreets(x - 1, y);
							level.updateStreets(x, y + 1);
							level.updateStreets(x, y - 1);
							updateGO(x + 1, y);
							updateGO(x - 1, y);
							updateGO(x, y + 1);
							updateGO(x, y - 1);
							mesh.mesh = street[block.modelID];
							mesh.transform.rotation = block.rotation * 0.0174532925f;
						}
						break;
					case 1:
						if(!level.hasBlock(x, y))
						{
							auto mesh = addMesh(houses_low[2], materials["houseL1"], gridToAbsolute(vec3(x, 0, y)), vec3(0));
							mesh.data = cast(void*)1;
							level.add(&mesh, x, y, "houses_low", 2, 0, "houseL1", 0, BlockType.Residential);
						}
						break;
					case 2:
						if(level.hasBlock(x, y) && level.getBlock(x, y).type == BlockType.Street)
						{
							startP = new Waypoint();
							startP.x = x;
							startP.y = y;
							startP.cost = 0;
							startP.heuristic = 0;
							startP.prev = null;
							writeln("Set Start");
						}
						break;
					case 3:
						if(level.hasBlock(x, y) && level.getBlock(x, y).type == BlockType.Street)
						{
							endP = new Waypoint();
							endP.x = x;
							endP.y = y;
							endP.cost = 0;
							endP.heuristic = 0;
							endP.prev = null;
							writeln("Set End");
						}
						break;
					case 4:
						int[] blocks = new int[cast(int)level.width * cast(int)level.height];

						for(int xx = 0; xx < cast(int)level.width; xx++)
						{
							for(int yy = 0; yy < cast(int)level.height; yy++)
							{
								if(level.hasBlock(xx, yy) && level.getBlock(xx, yy).type == BlockType.Street)
								{
									if(level.getBlock(xx, yy).modelID == 0)
										blocks[xx + yy * cast(int)level.width] = 1;
									if(level.getBlock(xx, yy).modelID == 5)
										blocks[xx + yy * cast(int)level.width] = 1;
									if(level.getBlock(xx, yy).modelID == 3)
										blocks[xx + yy * cast(int)level.width] = 1;
									if(level.getBlock(xx, yy).modelID == 2)
										blocks[xx + yy * cast(int)level.width] = 2;
									if(level.getBlock(xx, yy).modelID == 1)
										blocks[xx + yy * cast(int)level.width] = 3;
								}
								else
									blocks[xx + yy * cast(int)level.width] = 999;
							}
						}
						
						writeln("Calculating");
						astar = new AStar(startP, endP, blocks, cast(int)level.width, cast(int)level.height);
						if(astar.calculate(points))
						{
							writeln("Calced");
						}
						else
						{
							writeln("Failed");
						}
						break;
					default:
						break;
					}
				}
				if(cTool == 10000)
				{
					if(level.hasBlock(x, y))
					{
						if(keyboard.isKeyDown(SDLK_LSHIFT))
						{
							auto sur = getSurronding(x, y, level.getBlock(x, y).type);
							foreach(u32vec2 block; sur)
							{
								remove(block);
							}
						}
						else
						{
							remove(x, y);
						}
					}
				}
			}
		}
		else
		{
			hover.transform.position = vec3(-10000, 0, -10000);
		}

		if(destroyQuery.length > 0)
		{
			int x = cast(int)destroyQuery[destroyQuery.length - 1].x;
			int y = cast(int)destroyQuery[destroyQuery.length - 1].y;

			destroyQuery.length--;

			system.add(Particle(gridToAbsolute(vec3(x, 3, y) + vec3(random.nextFloat() - 0.5f, 0, random.nextFloat() - 0.5f)), vec3(random.nextFloat() - 0.5f, 3.0f, random.nextFloat() - 0.5f) * 0.05f, vec3(0.1f), vec3(0.02f, 0.02f, 0.02f), vec3(0), vec3(0), 0, new ParticleMesh(smoke[0], materials["smoke"])));
			system.add(Particle(gridToAbsolute(vec3(x, 3, y) + vec3(random.nextFloat() - 0.5f, 0, random.nextFloat() - 0.5f)), vec3(random.nextFloat() - 0.5f, 3.0f, random.nextFloat() - 0.5f) * 0.05f, vec3(0.1f), vec3(0.02f, 0.02f, 0.02f), vec3(0), vec3(0), 0, new ParticleMesh(smoke[0], materials["smoke"])));
			system.add(Particle(gridToAbsolute(vec3(x, 3, y) + vec3(random.nextFloat() - 0.5f, 0, random.nextFloat() - 0.5f)), vec3(random.nextFloat() - 0.5f, 3.0f, random.nextFloat() - 0.5f) * 0.05f, vec3(0.1f), vec3(0.02f, 0.02f, 0.02f), vec3(0), vec3(0), 0, new ParticleMesh(smoke[0], materials["smoke"])));
			system.add(Particle(gridToAbsolute(vec3(x, 3, y) + vec3(random.nextFloat() - 0.5f, 0, random.nextFloat() - 0.5f)), vec3(random.nextFloat() - 0.5f, 3.0f, random.nextFloat() - 0.5f) * 0.05f, vec3(0.1f), vec3(0.02f, 0.02f, 0.02f), vec3(0), vec3(0), 0, new ParticleMesh(smoke[0], materials["smoke"])));
			system.add(Particle(gridToAbsolute(vec3(x, 3, y) + vec3(random.nextFloat() - 0.5f, 0, random.nextFloat() - 0.5f)), vec3(random.nextFloat() - 0.5f, 3.0f, random.nextFloat() - 0.5f) * 0.05f, vec3(0.1f), vec3(0.02f, 0.02f, 0.02f), vec3(0), vec3(0), 0, new ParticleMesh(smoke[0], materials["smoke"])));

			level.remove(x, y);
			level.updateStreets(x + 1, y);
			level.updateStreets(x - 1, y);
			level.updateStreets(x, y + 1);
			level.updateStreets(x, y - 1);
			updateGO(x + 1, y);
			updateGO(x - 1, y);
			updateGO(x, y + 1);
			updateGO(x, y - 1);
			updateGO(x, y);
		}

		level.updateHouses();
		
		for(int x = 0; x < 20; x++)
		{
			for(int y = 0; y < 20; y++)
			{
				updateGO(x, y);
			}
		}
	}

	u32vec2[] getSurronding(int x, int y, BlockType type)
	{
		u32vec2[] blocks;

		for(int xo = -2; xo <= 2; xo++)
		{
			for(int yo = -2; yo <= 2; yo++)
			{
				if(inBounds(x + xo, y + yo) && level.hasBlock(x + xo, y + yo))
				{
					if(level.getBlock(x + xo, y + yo).type == type)
					{
						blocks.length++;
						blocks[blocks.length - 1] = u32vec2(x + xo, y + yo);
					}
				}
			}
		}

		return blocks;
	}

	bool inBounds(int x, int y)
	{
		return !(x < 0 || y < 0 || x >= level.width || y >= level.height);
	}

	void remove(u32vec2 v)
	{
		if(!inBounds(v.x, v.y)) return;
		for(int i = 0; i < destroyQuery.length; i++) { if(destroyQuery[i].x == v.x && destroyQuery[i].y == v.y) return; }

		destroyQuery.reverse();
		destroyQuery.length++;
		destroyQuery[destroyQuery.length - 1] = v;
		destroyQuery.reverse();
	}

	void remove(int x, int y)
	{
		remove(u32vec2(cast(u32)x, cast(u32)y));
	}

	void updateGO(int x, int y)
	{
		GameObject[] gos = gameObjects;

		foreach(GameObject obj; gos)
		{
			if(obj.data == cast(void*)1 && cast(int)(obj.transform.position.x * 0.1f + 10.5f) == x && cast(int)(obj.transform.position.z * 0.1f + 10.5f) == y)
			{
				if(!level.hasBlock(x, y))
				{
					removeGameObject(obj);
					return;
				}

				auto block = level.getBlock(x, y);
				(cast(MeshObject)obj).mesh = meshes[block.model][block.modelID];
				(cast(MeshObject)obj).material = materials[block.material];
				obj.transform.rotation = block.rotation * 0.0174532925f;
			}
		}
	}
	
	vec3 gridToAbsolute(vec3 grid)
	{
		return vec3(grid.x * level.blockX - level.width * 0.5f * level.blockX, grid.y, grid.z * level.blockY - level.height * 0.5f * level.blockY);
	}

	override void destroy()
	{
		writeln("Saving...");
		level.save("saves/save0_auto.json");
		super.destroy;
	}
}

class GameGUILayer : RenderLayer
{
	GameObject[] obj;
	float f = 0;
	Scene scene;

	override void init(Scene scene) {
		this.scene = scene;
		obj ~= addMesh(meshes["street"][0], materials["street"], vec3(170, 0, -100), vec3(0), vec3(3, 1, 3));
		obj ~= addMesh(meshes["houses_low"][0], materials["houseL1"], vec3(170, 0, -60), vec3(0), vec3(3, 1, 3));
		obj ~= addMesh(meshes["houses_low"][1], materials["houseL1"], vec3(170, 0, -20), vec3(0), vec3(3, 1, 3));
		obj ~= addMesh(meshes["houses_low"][2], materials["houseL1"], vec3(170, 0, 20), vec3(0), vec3(3, 1, 3));
		obj ~= addMesh(meshes["houses_low"][3], materials["houseL1"], vec3(170, 0, 60), vec3(0), vec3(3, 1, 3));
		obj ~= addMesh(meshes["houses_low"][4], materials["houseL1"], vec3(170, 0, 100), vec3(0), vec3(3, 1, 3));
	}
	
	private GameObject addMesh(Mesh mesh, Material material, vec3 position, vec3 rotation = vec3(0), vec3 scale = vec3(1))
	{
		auto obj = new MeshObject(mesh, material);
		obj.transform.position = position;
		obj.transform.rotation = rotation;
		obj.transform.scale = scale;
		addGameObject(obj);
		return obj;
	}

	override protected void update(f64 deltaTime)
	{
		f += 0.003f;
		foreach(GameObject o; obj)
			o.transform.rotation.y = f;
			
		const float inputStartX = 1600 / 1920.0f;
		const float inputStartY = 40 / 1080.0f;

		const float inputStepY = 180 / 1080.0f;

		u32vec2 v = scene.view.size;

		float mousePosX = mouse.position.x / cast(float)v.x;
		float mousePosY = mouse.position.y / cast(float)v.y;

		for(int i = 0; i < obj.length; i++)
			obj[i].transform.position.y = 0;
		if(mousePosX > inputStartX)
		{
			int y = cast(int)((mousePosY - inputStartY) / inputStepY);

			if(y >= 0 && y < obj.length)
			{
				obj[y].transform.position.y = 5;

				if(wasDown && mouse.isButtonUp(0))
				{
					cTool = y;

					if(y == obj.length - 1) cTool = 10000;
				}
			}
			else
			{
				if(wasDown && mouse.isButtonUp(0))
				{
					cTool = -1;
				}
			}
		}
	}
	
}

class GameScene : Scene
{
	override void init()
	{
		addLayer(new Game3DLayer());
		addLayer(new GameGUILayer());
	}
}