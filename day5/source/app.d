immutable INPUT = import("input.txt");
immutable MAX_PARAMETERS = 3;

enum ParamMode
{
    Position,
    Immediate
}

enum Instruction
{
    Add         = 1,
    Mul         = 2,
    In          = 3,
    Out         = 4,
    Jnz         = 5,
    Jz          = 6,
    Lt          = 7,
    Eq          = 8,
    Terminate   = 99
}

struct Opcode
{
    ParamMode[MAX_PARAMETERS] paramModes;
    Instruction instruction;

    this(int opcode)
    {
        import std.conv : to;

        this.instruction = (opcode % 100).to!Instruction;

        auto index = 0;
        while(true)
        {
            const delta = (10 ^^ (index + 2)); // e.g 100, then 1000
            if(opcode < delta)
                break;

            this.paramModes[index] = ((opcode / delta) % 10).to!ParamMode;
            index++;
        }
    }
    ///
    unittest
    {
        import std.format : format;

        auto opcode = Opcode(1002);
        assert(opcode.instruction == Instruction.Mul);
        assert(opcode.paramModes == [
            ParamMode.Position,
            ParamMode.Immediate,
            ParamMode.Position
        ], format("%s", opcode.paramModes));
    }
}

final class IntcodeCPU
{
    private
    {
        int[] _memory;
        size_t _ip;
    }

    public final
    {
        void loadMemoryFromString(string memory)
        {
            import std.algorithm : splitter, map;
            import std.array	 : array;
            import std.conv      : to;
            import std.string    : strip;
            import std.stdio     : writeln;

            this._memory = memory.splitter(',')
                                 .map!strip
                                 .map!(to!int)
                                 .array;
            this._ip = 0;

            writeln("Loaded ", this._memory.length, " values into memory.");
        }

        void execute(int delegate() getInput, void delegate(int) output)
        {
            while(true)
            {
                auto opcode = this.nextOpcode();
                
                final switch(opcode.instruction) with(Instruction)
                {
                    case Add:
                        const left    = this.paramRead(opcode.paramModes[0]);
                        const right   = this.paramRead(opcode.paramModes[1]);
                        const address = this.immediateModeRead();

                        this.store(address, left + right);
                        break;

                    case Mul:
                        const left    = this.paramRead(opcode.paramModes[0]);
                        const right   = this.paramRead(opcode.paramModes[1]);
                        const address = this.immediateModeRead();
                        this.store(address, left * right);
                        break;
                    
                    case In:
                        const address = this.immediateModeRead();
                        this.store(address, getInput());
                        break;

                    case Out:
                        const address = this.immediateModeRead();
                        output(this._memory[address]);
                        break;

                    case Jnz:
                        const value   = this.paramRead(opcode.paramModes[0]);
                        const address = this.paramRead(opcode.paramModes[1]);

                        if(value != 0)
                            this._ip = address;
                        break;

                    case Jz:
                        const value   = this.paramRead(opcode.paramModes[0]);
                        const address = this.paramRead(opcode.paramModes[1]);

                        if(value == 0)
                            this._ip = address;
                        break;

                    case Lt:
                        const left    = this.paramRead(opcode.paramModes[0]);
                        const right   = this.paramRead(opcode.paramModes[1]);
                        const address = this.immediateModeRead();
                        this.store(address, (left < right) ? 1 : 0);
                        break;

                    case Eq:
                        const left    = this.paramRead(opcode.paramModes[0]);
                        const right   = this.paramRead(opcode.paramModes[1]);
                        const address = this.immediateModeRead();
                        this.store(address, (left == right) ? 1 : 0);
                        break;

                    case Terminate:
                        return;
                }
            }
        }
    }

    private final
    {
        void store(int address, int value)
        {
            import std.stdio : writeln;
            //writeln("Storing value ", value, " into address ", address, ". Old value was ", this._memory[address]);
            this._memory[address] = value;
        }

        int nextRawValue()
        {
            return this._memory[this._ip++];
        }

        int postionModeRead()
        {
            return this._memory[this.nextRawValue()];
        }

        alias immediateModeRead = nextRawValue;

        Opcode nextOpcode()
        {
            return Opcode(this.nextRawValue);
        }

        int paramRead(ParamMode mode)
        {
            final switch(mode) with(ParamMode)
            {
                case Position:  return this.postionModeRead();
                case Immediate: return this.immediateModeRead();
            }
        }
    }
}

void main()
{
    import std.stdio : writeln;

    auto cpu = new IntcodeCPU();
    cpu.loadMemoryFromString(INPUT);
    cpu.execute(() => 1, value => writeln(value));

    cpu.loadMemoryFromString(INPUT);
    cpu.execute(() => 5, value => writeln(value));
}
