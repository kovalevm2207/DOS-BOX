#include <stdio.h>
#include <TXLib.h>
#include <assert.h>

#define FREE(ptr) free(ptr);    \
                  ptr = NULL

const int StartByteNum  = 16;

int PrintHelp();
bool AnalyzeInPrompt(int argc, const char* const* argv);


int main(int argc, const char* const* argv)
{
    int* ByteNums = (int*) calloc(StartByteNum, sizeof(int));
    assert(ByteNums && "Memory allocation err");

    bool CheckResult = AnalyzeInPrompt(argc, argv);
    if (!CheckResult)
    {
        FREE(ByteNums);
        return 0;
    }

    FREE(ByteNums);

    return 0;
}

bool AnalyzeInPrompt(int argc, const char* const* argv)
{
    assert(argv && "Null argv[]");

    if(argc != 3)
    {
        PrintHelp();
        return false;
    }

    return true;
}

int PrintHelp()
{
    int RetVal = printf("Формат входной строки имеет следующий вид:\n");
    RetVal += printf("    BinaryPatch.exe File.txt 37 41 89\n");
    RetVal += printf("File.txt - имя файла для взлома\n");
    RetVal += printf("37 41 89 - номера байтов в файле File.txt которые будут заменены на '90' (код команды nop)\n");

    return RetVal;
}
