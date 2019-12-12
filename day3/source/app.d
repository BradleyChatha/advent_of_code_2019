immutable INPUT = import("input.txt");

enum Direction
{
    Unknown,
    Up,
    Down,
    Left,
    Right
}

struct Point
{
    int x;
    int y;
    int step;

    int distance()
    {
        import std.math : abs;

        return this.x.abs + this.y.abs;
    }
}

struct Line
{
    Point start;
    Point end;
    Direction direction;

    string debug_movement;

    void allPointsList(ref Point[] list, ref int stepsSoFar) const
    {
        import std.algorithm : map;
        import std.range     : enumerate, iota, drop;

        void populateList(R)(R range, size_t count)
        {
            list.length = count;
            foreach(i, point; range.drop(1).enumerate) // Skip the first point, as it'll have already been counted last time.
            {
                list[i] = point;
            }
        }

        // The "+ 1" and "- 1" will make the iotas inclusive.
        final switch(this.direction) with(Direction)
        {
            case Unknown: assert(false);

            case Up: populateList(
                iota(this.start.y, this.end.y + 1, +1)
                .map!(y => Point(this.start.x, y, stepsSoFar++)),
                this.end.y - this.start.y
            );
            break;

            case Down: populateList(
                iota(this.start.y, this.end.y - 1, -1)
                .map!(y => Point(this.start.x, y, stepsSoFar++)),
                this.start.y - this.end.y
            );
            break;

            case Left: populateList(
                iota(this.start.x, this.end.x - 1, -1)
                .map!(x => Point(x, this.start.y, stepsSoFar++)),
                this.start.x - this.end.x
            );
            break;

            case Right: populateList(
                iota(this.start.x, this.end.x + 1, +1)
                .map!(x => Point(x, this.start.y, stepsSoFar++)),
                this.end.x - this.start.x
            );
            break;
        }
    }
    ///
    unittest
    {
        import std.format : format;

        Point[] points;

        void test(Line line, Point[] expectedPoints)
        {
            int dummy = 0;
            line.allPointsList(points, dummy);
            assert(expectedPoints == points, format("Expected: %s\nGot: %s", expectedPoints, points));
        }

        test(Line(Point(0, 0), Point(5, 0), Direction.Right), [
            Point(1, 0, 0), Point(2, 0, 1), Point(3, 0, 2), Point(4, 0, 3), Point(5, 0, 4)
        ]);

        test(Line(Point(0, 0), Point(-5, 0), Direction.Left), [
            Point(-1, 0, 0), Point(-2, 0, 1), Point(-3, 0, 2), Point(-4, 0, 3), Point(-5, 0, 4)
        ]);

        test(Line(Point(0, 0), Point(0, 5), Direction.Up), [
            Point(0, 1, 0), Point(0, 2, 1), Point(0, 3, 2), Point(0, 4, 3), Point(0, 5, 4)
        ]);

        test(Line(Point(0, 0), Point(0, -5), Direction.Down), [
            Point(0, -1, 0), Point(0, -2, 1), Point(0, -3, 2), Point(0, -4, 3), Point(0, -5, 4)
        ]);
    }

    bool intersects(const Line line, out Point myIntersect, out Point theirIntersect, ref int mySteps, ref int theirSteps) const
    {
        static Point[] myPoints;
        static Point[] theirPoints;

        this.allPointsList(myPoints, mySteps);
        line.allPointsList(theirPoints, theirSteps);

        foreach(myPoint; myPoints)
        {
            foreach(theirPoint; theirPoints)
            {
                if(myPoint.x == theirPoint.x && myPoint.y == theirPoint.y)
                {
                    myIntersect = myPoint;
                    theirIntersect = theirPoint;
                    return true;
                }
            }
        }

        return false;
    }
    ///
    unittest
    {
        import std.format : format;

        auto l1 = Line(Point(0, 0), Point(20, 0), Direction.Right);
        auto l2 = Line(Point(10, 5), Point(10, -5), Direction.Down);

        Point l1Intersect;
        Point l2Intersect;
        int   l1Steps;
        int   l2Steps;
        assert(l1.intersects(l2, l1Intersect, l2Intersect, l1Steps, l2Steps));

        assert(l1Intersect == Point(10, 0, 9));
        assert(l2Intersect == Point(10, 0, 4));
        assert(l1Steps     == 20); // The steps end up being left on what the NEXT step will be, not what the CURRENT step is.
        assert(l2Steps     == 10);
    }

    int steps() const
    {
        final switch(this.direction) with(Direction)
        {
            case Unknown: assert(false);

            // '- 1' to ignore the first step, as it'd have already been counted
            case Up:    return (this.end.y - this.start.y) - 1;
            case Down:  return (this.start.y - this.end.y) - 1;
            case Left:  return (this.start.x - this.end.x) - 1;
            case Right: return (this.end.x - this.start.x) - 1;
                
        }
    }
}

void main()
{
    solve(INPUT);
}

void solve(string input)
{
    import std.algorithm : map;
    import std.array	 : array;
    import std.stdio     : writeln;

    const lineInfo = getLineInfo(input);
    const lines    = lineInfo.map!generateLinesFromInfo
                             .array;

    assert(lines.length == 2, "More than two wires ;(");

    auto lineOneTotalSteps      = 1; // Start at 1 to count the center point, since it will otherwise get ignored.
    auto closestIntersection    = Point(int.max / 4, int.max / 4); // Divide by 4 so .distance doesn't overflow.
    auto leastStepsIntersection = Point();
    auto leastSteps             = int.max;
    foreach(line; lines[0])
    {
        auto lineTwoTotalSteps = 1;
        foreach(otherLine; lines[1])
        {
            Point myIntersect;
            Point theirIntersect;
            int   lineOneTempSteps = lineOneTotalSteps;
            const lineOneOldSteps  = lineOneTempSteps;
            const lineTwoOldSteps  = lineTwoTotalSteps;

            const intersects = line.intersects(otherLine, myIntersect, theirIntersect, lineOneTempSteps, lineTwoTotalSteps);

            // If this is the last line, also update line one's total steps.   
            if(otherLine == lines[1][$-1])
                lineOneTotalSteps = lineOneTempSteps;

            if(intersects)
            {
                if(myIntersect.distance < closestIntersection.distance)
                    closestIntersection = myIntersect;

                // Change the ends of the lines to their intersections, then add these steps to the OLD
                // values to properly determine how many steps were done.
                Line lineOneIntersect = line;
                Line lineTwoIntersect = otherLine;
                
                lineOneIntersect.end = myIntersect;
                lineTwoIntersect.end = theirIntersect;

                const lineOneIntersectSteps = lineOneOldSteps + lineOneIntersect.steps;
                const lineTwoIntersectSteps = lineTwoOldSteps + lineTwoIntersect.steps;
                const totalIntersectSteps   = lineOneIntersectSteps + lineTwoIntersectSteps;

                if(totalIntersectSteps < leastSteps)
                {
                    leastSteps = totalIntersectSteps;
                    leastStepsIntersection = myIntersect;
                }
            }
        }
    }

    writeln("Part one: ", closestIntersection, " | Distance: ", closestIntersection.distance);
    writeln("Part two: ", leastStepsIntersection, " | Total Steps: ", leastSteps);
}

string[] getLineInfo(string input)
{
    import std.algorithm : splitter, filter;
    import std.array	 : array;

    return input.splitter
                .filter!(line => line.length > 0)
                .array;
}

Direction directionFromChar(char direction)
{
    switch(direction) with(Direction)
    {
        case 'U': return Up;
        case 'R': return Right;
        case 'D': return Down;
        case 'L': return Left;

        default: assert(false, "" ~ direction);
    }
}

Point moveInDirection(Point from, Direction direction, int amount)
{
    final switch(direction) with(Direction)
    {
        case Unknown: assert(false, "Cannot be unknown");

        case Up: 	return Point(from.x, 		  from.y + amount);
        case Right: return Point(from.x + amount, from.y);
        case Down: 	return Point(from.x, 		  from.y - amount);
        case Left: 	return Point(from.x - amount, from.y);
    }
}

Line[] generateLinesFromInfo(string info)
{
    import std.algorithm : splitter, map;
    import std.array	 : array;
    import std.conv      : to;

    auto previous = Line(Point(0, 0), Point(0, 0), Direction.Unknown);

    return info.splitter(',')
               .map!((movement) 
               {
                   auto current 	 	  = previous;
                   current.direction 	  = directionFromChar(movement[0]);
                   current.start 	 	  = current.end;
                   current.end		      = moveInDirection(current.start, current.direction, movement[1..$].to!int);
                   current.debug_movement = movement;

                   previous = current;
                   return current;
               })
               .array;
}