#include <iostream>
#include <map>
#include <vector>
#include <string>

using namespace std;

enum type{
  intType,
  realType,
  boolType,
  strType,
  arrayType,
  voidType,
  charType
};

enum idFlag {
  constValueFlag,
  constVariableFlag,
  variableFlag,
  functionFlag
};


struct idValue;
struct idInfo;

struct idValue {
  int int_val = 0;
  double double_val = 0;
  bool bool_val = false;
  string str_val = "";
  vector<idInfo> array_val;//array
  int arr_start_index = -1;
  int arr_end_index = -1;
};


struct idInfo {
  int index = 0;
  string id = "";
  int type = intType;
  int flag = variableFlag;
  idValue value;
  bool init = false;
};

class SymbolTable {
  private:
    vector<string> symbols;
    map<string, idInfo> table_map;
    int index;
  public:
    SymbolTable();
    int insert(string id, int type, int flag, idValue value, bool init);
    idInfo *lookup(string id);
    void dump();
    bool isExist(string id);
    void setFuncType(int type);
    void addFuncArg(string id, idInfo info);
};

class SymbolTableList {
  private:
    vector<SymbolTable> list;
    int top;
  public:
    SymbolTableList();
    void push();
    bool pop();
    int insert(string id, idInfo info);
    int insert(string id, int type, int s_index,int e_index);
    idInfo *lookup(string id);
    void dump();
    void setFuncType(int type);
    void addFuncArg(string id, idInfo info);
};

/* utilities */

bool isConst(idInfo info);
idInfo *intConst(int val);
idInfo *realConst(double val);
idInfo *boolConst(bool val);
idInfo *strConst(string *val);
