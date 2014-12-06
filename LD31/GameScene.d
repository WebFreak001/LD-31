module GameScene;

import EncoShared;
import EncoDesktop;
import EncoGL3;

import std.stdio;
import std.algorithm;

import Level;
import NoDepthComponent;
import ParticleSystem;

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
bool wasDown;
int cTool;

class Game3DLayer : RenderLayer
{
	Random random;
	Scene scene;

	MeshObject hover;
	Level* level;

	u32vec2[] destroyQuery;

	u32vec2 start;

	ParticleSystem system;

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
			if(level.blocks[i].type == BlockType.Residential)
				system.addEmitter(vec3(level.blocks[i].position.x * level.blockX - level.width * 0.5f * level.blockX, 3, level.blocks[i].position.z * level.blockY - level.height * 0.5f * level.blockY));
			addMesh(meshes[level.blocks[i].model][level.blocks[i].modelID], materials[level.blocks[i].material], vec3(level.blocks[i].position.x * level.blockX - level.width * 0.5f * level.blockX, 0, level.blocks[i].position.z * level.blockY - level.height * 0.5f * level.blockY), level.blocks[i].rotation * 0.0174532925f).data = cast(void*)1;
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
	}
	

	override protected void update(f64 deltaTime)
	{
		level.update();

		if(mouse != null)
		wasDown = mouse.isButtonDown(0);
		mouse = Mouse.getState();

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

			if(wasDown && mouse.isButtonUp(0))
			{
				if(cTool >= 0 && cTool <= 1)
				{
					switch(cTool)
					{
					case 0:
						if(!level.hasBlock(x, y))
						{
							auto mesh = addMesh(street[0], materials["street"], vec3(x * level.blockX - level.width * 0.5f * level.blockX, 0, y * level.blockY - level.height * 0.5f * level.blockY), vec3(0));
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
							auto mesh = addMesh(houses_low[2], materials["houseL1"], vec3(x * level.blockX - level.width * 0.5f * level.blockX, 0, y * level.blockY - level.height * 0.5f * level.blockY), vec3(0));
							mesh.data = cast(void*)1;
							level.add(&mesh, x, y, "houses_low", 2, 0, "houseL1", 0, BlockType.Residential);
						}
						break;
					default:
						break;
					}
				}
				if(cTool == 10000)
				{
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
			}
		}
		else
		{
			hover.transform.position = vec3(-10000, 0, -10000);
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

	void remove(u32vec2 v) { remove(cast(int)v.x, cast(int)v.y); }

	void remove(int x, int y)
	{
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
		obj ~= addMesh(meshes["houses_low"][0], materials["houseL1"], vec3(170, 0, -20), vec3(0), vec3(3, 1, 3));
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