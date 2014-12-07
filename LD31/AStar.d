module AStar;

import std.algorithm;
import std.math;
import std.stdio;

class Waypoint
{
	int x, y;
	int cost;
	int heuristic;

	Waypoint prev;

	this()
	{
		x = 0;
		y = 0;
		cost = 0;
		heuristic = 0;
		prev = null;
	}

	this(int x, int y, int cost, int heuristic, Waypoint prev)
	{
		this.x = x;
		this.y = y;
		this.cost = cost;
		this.heuristic = heuristic;
		this.prev = prev;
	}

	@property int totalCost()
	{
		return prevCost + cost + heuristic;
	}

	@property int prevCost()
	{
		if(prev is null) return 0;
		return prev.prevCost() + cost;
	}
}

class AStar
{
	Waypoint start, end;

	int[] blocks;

	int width, height;

	this(Waypoint start, Waypoint end, int[] blocks, int width, int height)
	{
		assert(blocks.length / width == height);
		
		this.start = start;
		this.end = end;
		this.blocks = blocks[];
		this.width = width;
		this.height = height;
	}

	bool calculate(out Waypoint[] waypoints)
	{
		
		Waypoint[] open;
		Waypoint[] closed;

		open.length++;
		open[0] = start;

		waypoints = [];

		const int maxIter = 10000;

		for(int iter = 0; iter < maxIter; iter++)
		{
			if(open.length == 0)
			{
				writeln("No Path");
				waypoints = [];
				return false;
			}
			Waypoint best = open[getFirstBest(open)];
			closed.length++;
			closed[closed.length - 1] = open[getFirstBest(open)];
			open = remove!(p => p.x == best.x && p.y == best.y)(open);
			if(best.x == end.x && best.y == end.y)
			{
				waypoints = [];

				waypoints.length++;
				waypoints[0] = best;

				while(best.prev !is null)
				{
					waypoints.length++;
					waypoints[waypoints.length - 1] = best.prev;
					best = best.prev;
				}
				writeln("Done");
				return true;
			}
			
			open = addOpen(best.x + 1, best.y, open, closed, best);
			open = addOpen(best.x - 1, best.y, open, closed, best);
			open = addOpen(best.x, best.y + 1, open, closed, best);
			open = addOpen(best.x, best.y - 1, open, closed, best);

			waypoints.length++;
			waypoints[waypoints.length - 1] = best;
		}
		
		writeln("Aborting");
		waypoints = [];
		return false;
	}

	private Waypoint[] addOpen(int x, int y, Waypoint[] open, Waypoint[] closed, Waypoint prev)
	{
		if(x < 0 || y < 0 || x >= width || y >= height)
			return open;
		if(!isInList(x, y, closed) && blocks[x + y * width] < 999 && !isInList(x, y, open))
		{
			open.length++;
			open[open.length - 1] = new Waypoint(x, y, blocks[x + y * width], heuristic(x, y), prev);
		}
		return open;
	}

	private int heuristic(int x, int y)
	{
		int dx = abs(x - end.x);
		int dy = abs(y - end.y);
		return dx + dy;
	}

	private int getFirstBest(Waypoint[] points)
	{
		int best = points[0].totalCost;

		for(int i = 1; i < points.length; i++)
		{
			if(points[i].totalCost < best)
			{
				best = points[i].totalCost;
			}
		}

		for(int i = 0; i < points.length; i++)
		{
			if(cast(int)points[i].totalCost == cast(int)best) return i;
		}

		assert(0);
	}

	private bool isInList(int x, int y, Waypoint[] points)
	{
		for(int i = 0; i < points.length; i++)
		{
			if(points[i].x == x && points[i].y == y) return true;
		}
		return false;
	}
}