import std.typecons : Flag;

immutable INPUT = import("input.txt");
immutable DIGIT_COUNT = 6;

alias PartTwo = Flag!"partTwo";

struct Range
{
    int low;
    int high;

    this(string input)
    {
        import std.algorithm : splitter, map;
        import std.conv      : to;

        auto range = input.splitter('-')
                          .map!(to!int);

        this.low = range.front;
        range.popFront();
        this.high = range.front;
    }
}

void main()
{
    solve(Range(INPUT), PartTwo.no);
    solve(Range(INPUT), PartTwo.yes);
}

void solve(const Range range, const PartTwo partTwo)
{
    import std.stdio : writeln;

    int count = 0;
    int number = range.low;
    while(number < range.high)
    {
        if(range.fitsRuleset(number++, partTwo))
        {
            count++;
            writeln(number - 1);
        }
    }

    writeln(count);
}

bool fitsRuleset(const Range range, const int number, const PartTwo partTwo = PartTwo.no)
{
    if(number < range.low || number > range.high)
        return false;

    auto foundDouble = false;
    auto lastDigit   = number.getDigit(DIGIT_COUNT-1);
    foreach(digitIndex; digitLeftToRightIndicies())
    {
        const digit = number.getDigit(digitIndex);
        if(digit < lastDigit)
            return false;

        if(digit == lastDigit)
        {
            if(partTwo)
            {
                int digitCount = 1;
                // I love being an awful programmer.
                // Really makes me feel special that I'm too retarded to do this another way.
                foreach(backIndex; digitIndex + 1..DIGIT_COUNT)
                {
                    if(number.getDigit(backIndex) == digit)
                        digitCount++;
                    else
                        break;
                }

                for(int forwardIndex = digitIndex - 1; forwardIndex > -1; forwardIndex--)
                {
                    if(number.getDigit(forwardIndex) == digit)
                        digitCount++;
                    else
                        break;
                }

                if(digitCount == 2)
                    foundDouble = true;

                // ayyy I'm a retard.
            }
            else
                foundDouble = true;
        }

        lastDigit = digit;
    }

    return foundDouble;
}
///
unittest
{
    Range range;
    range.low = 0;
    range.high = int.max;
    assert(fitsRuleset(range, 111111));
    assert(!fitsRuleset(range, 223450));
    assert(!fitsRuleset(range, 123789));
    assert(fitsRuleset(range, 333333));
}

// EXCLUDES LEFT-MOST DIGIT INDEX
auto digitLeftToRightIndicies()
{
    import std.range : iota;
    return iota(DIGIT_COUNT - 2, -1, -1);
}

int getDigit(const int number, const int digit)
{
    return (number / (10 ^^ digit)) % 10;
}
///
unittest
{
    assert(getDigit(4321, 0) == 1);
    assert(getDigit(4321, 1) == 2);
    assert(getDigit(4321, 2) == 3);
    assert(getDigit(4321, 3) == 4);
    assert(getDigit(4321, 4) == 0);
}