#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <TXLib.h>
#include <assert.h>

#define FREE(ptr) free(ptr);    \
                  ptr = NULL

#define CLOSE(file)     fclose(file); \
                        file = NULL

int PrintHelp();
bool AnalyzeInPrompt(const int argc, const char* const* argv, int* ByteNums);
FILE* MakeCopy(const char* const Name);
FILE* MakeCopyName(const char* const Name, const char* const AddedName);
bool MakePatch(const FILE* const file, const int* const ByteNums);

int main(int argc, const char* const* argv)
{
    assert(argv && "Null argv[]");
    assert(argc && "argc == 0");

    int* ByteNums = (int*) calloc(argc - 2, sizeof(int));
    assert(ByteNums && "Memory allocation err");

    bool CheckResult = AnalyzeInPrompt(argc, argv, ByteNums);
    if (!CheckResult)
    {
        FREE(ByteNums);
        return 1;
    }

    FILE* File = fopen(argv[1], "rb+");
    assert(File && "file not found");

    FILE* Copy = MakeCopy(argv[1]);
    if(!Copy)
    {
        fprintf(stderr, "Не удалось создать копию файла %s\n", argv[1]);
        return 1;
    }

    MakePatch(Copy, ByteNums, argc - 2);

    CLOSE(Copy);
    FREE(ByteNums);

    return 0;
}

bool AnalyzeInPrompt(int argc, const char* const* argv, int* ByteNums)
{
    assert(argv && "Null argv[]");
    assert(argc && "argc == 0");

    if(argc < 3)    // File.exe File.txt 41
    {
        PrintHelp();
        return false;
    }

    FILE* File = fopen(argv[1], "rb+");      // try to open file, for check it
    if(!File)
    {
        fprintf(stderr, "Не найден файл для взлома, проверьте его написание и наличие в директории, содержащей исполняемый файл BinaryPatch.exe\n");
        return false;
    }

    fseek(File, 0, SEEK_END);
    int long FileSize = ftell(File);

    CLOSE(File);

    for(int i = 0; i < argc - 2/*File.exe File.txt*/; i++)
    {
        ByteNums[i] = atoi(argv[i+2]);

        if(((ByteNums[i] == 0) && (argv[i+2][0] != '0')) || (ByteNums[i] > FileSize) || (ByteNums[i] < 0))
        {
                fprintf(stderr ,"Недопустимый номер удаляемого байта, размер вашего файла составляет %ld байт,\n", FileSize);
                fprintf(stderr ,"А вы просите удалить меня %d байт, вы в своем уме?\n", ByteNums[i]);
                return false;
        }
    }

    return true;
}

int PrintHelp()
{
    int RetVal  = printf("Формат входной строки имеет следующий вид:\n");
        RetVal += printf("    BinaryPatch.exe File.txt 37 41 89\n");
        RetVal += printf("File.txt - имя файла для взлома\n");
        RetVal += printf("37 41 89 - номера байтов в файле File.txt которые будут заменены на '90' (код команды nop)\n");

    return RetVal;
}

bool MakePatch(const FILE* const File, const int* const ByteNums, const int Size)
{
    assert(File && "NULL file stream");
    assert(ByteNums && "NULL arr ptr");

    for(int i = 0; i < Size; i++)
    {
        fseek(File, ByteNums[i], SEEK_SET);
        fprintf(File, "%c", 'Z'/*90 = nop command code*/);
    }

    return true;
}

FILE* MakeCopy(const char* const Name)
{
    assert(Name && "NULL file name");

    const char* CopyName = MakeCopyName(Name, "hacked");
    if(!CopyName)
    {
        fprintf(stderr, "Не удалось создать имя для копии файла %s\n", Name);
        return NULL;
    }

    FILE* Copy = fopen(CopyName, "w");
    assert(Copy && "Can't open and create file %s", );

}

FILE* MakeCopyName(const char* const Name, const char* const AddedName)
{
    assert(Name && "NULL file name");

    size_t NameLen  = strlen(Name);
    size_t AddedLen = strlen(AddedName);

    char* CopyName = (char*) calloc(NameLen+AddedLen+1/*'\0'*/);
l   assert(CopyName && "Memory allocation err");

    CopyName[NameLen+AddedLen] = '\0';

    char* DotPos = strchr(Name, '.');
    if(!DotPos)
    {
        fprintf(stderr, "Не найдена '.', для создания имени копии фала %s\n", Name);
        FREE(CopyName);
        return NULL;
    }

    strncpy(CopyName, Name, DotPos-Name);

    FILE* List = fopen("Listing.txt", "rb+");
    fseek(List, 0, SEEK_END);
    assert(List && "Can't make and open file Listing.txt");

    fprintf(List, "command: strncpy(CopyName, Name, DotPos-Name);\n");
    fprintf(List, "result: %s\n\n", CopyName);

    strncpy(CopyName+(DotPos-Name), AddedName, AddedLen);

    fprintf(List, "command: strncpy(CopyName+(DotPos-Name), AddedName, AddedLen);\n");
    fprintf(List, "result: %s\n\n", CopyName);

    CLOSE(List);

    return CopyName;
}
