immutable INPUT = import("input.txt");

void main()
{
    partOne(INPUT);
    partTwo(INPUT);
}

int[] parseMemory(string input)
{
    import std.algorithm : splitter, map;
    import std.array	 : array;
    import std.conv      : to;
    import std.string    : strip;

    return input.splitter(',')
                .map!strip
                .map!(to!int)
                .array;
}

void partOne(string input)
{
    import std.stdio : writeln;

    auto memory = parseMemory(input);
    memory[1] = 12;
    memory[2] = 2;
    doCompute(memory);

    writeln("Part one: ", memory[0]);
}

void partTwo(string input)
{
    import std.stdio : writeln;

    auto memoryInit = parseMemory(input);
    auto memoryVolatile = memoryInit.dup;

    foreach(noun; 0..100)
    {
        foreach(verb; 0..100)
        {
            memoryVolatile[]  = memoryInit[];
            memoryVolatile[1] = noun;
            memoryVolatile[2] = verb;

            doCompute(memoryVolatile);

            if(memoryVolatile[0] == 19690720)
            {
                writeln("Part two: Noun=", noun, " | Verb=", verb, " | Result=", (100 * noun + verb));
                return;
            }
        }
    }
}

void doCompute(int[] memory)
{
    import std.conv		 : to;
    import std.exception : enforce;

    size_t i = 0;
    int nextOpcode()
    {
        return memory[i++];
    }

    while(true)
    {
        enforce(i < memory.length, "No termination opcode was found.");

        const opcode = nextOpcode();
        if(opcode == 99)
            break;

        const left = memory[nextOpcode()];
        const right = memory[nextOpcode()];

        switch(opcode)
        {
            case 1:
                memory[nextOpcode()] = (left + right);
                break;

            case 2:
                memory[nextOpcode()] = (left * right);
                break;

            default:
                throw new Exception("Illegal opcode: " ~ opcode.to!string);
        }
    }
}