#include "symbol.h"

SymbolTable::SymbolTable()
{
  index = 0;
}

int SymbolTable::insert(string id, int type, int flag, idValue value, bool init)
{
  if (table_map.find(id) != table_map.end()) {
    return -1;
  }
  else {
    symbols.push_back(id);
    table_map[id].index = index;
    table_map[id].id = id;
    table_map[id].type = type;
    table_map[id].flag = flag;
    table_map[id].value = value;
    table_map[id].init = init;
    return index++;
  }
}

idInfo *SymbolTable::lookup(string id)
{
  if (isExist(id)) return new idInfo(table_map[id]);
  else return NULL;
}

void SymbolTable::dump()
{
  cout << "-id-\t-flag-\t-type-\t-value-" << endl;
  string s;
  for (int i = 0; i < index; ++i)
  {
    idInfo info = table_map[symbols[i]];
    s = info.id + "\t";
    switch (info.flag) {
      case constVariableFlag: s += "const\t"; break;
      case variableFlag: s += "var\t"; break;
      case functionFlag: s += "func\t"; break;
    }
    switch (info.type) {
      case intType: s += "int\t"; break;
      case realType: s += "float\t"; break;
      case boolType: s += "bool\t"; break;
      case strType: s += "str\t"; break;
      case arrayType: s += "array\t"; break;
      case voidType: s += "void\t"; break;
    }
    if (info.init) {
      switch (info.type) {
        case intType: s += to_string(info.value.int_val); break;
        case realType: s += to_string(info.value.double_val); break;
        case boolType: s += (info.value.bool_val)? "true" : "false"; break;
        case strType: s += info.value.str_val; break;
      }
    }
    if (info.flag == functionFlag) {
      s += "{ ";
      for (int i = 0; i < info.value.array_val.size(); ++i) {
        switch (info.value.array_val[i].type) {
          case intType: s += "int "; break;
          case realType: s += "float "; break;
          case boolType: s += "bool "; break;
          case strType: s += "str "; break;
        }
      }
      s += "}";
    }
    if (info.type == arrayType) {
      s += "{ ";
      switch (info.value.array_val[0].type) {
        case intType: s += "int, "; break;
        case realType: s += "float, "; break;
        case boolType: s += "bool, "; break;
        case strType: s += "str, "; break;
      }
      s += to_string(info.value.array_val.size()) + " }";
    }
    cout << s << endl;
  }
  cout << endl;
}

bool SymbolTable::isExist(string id)//redefined check
{
  return table_map.find(id) != table_map.end();
}

void SymbolTable::setFuncType(int type)
{
  table_map[symbols[symbols.size() - 1]].type = type;
}

void SymbolTable::addFuncArg(string id, idInfo info)
{
  cout << id << endl;
  cout << info.type << endl;
  table_map[symbols[symbols.size() - 1]].value.array_val.push_back(info);
}

SymbolTableList::SymbolTableList()
{
  top = -1;
  push();
}

void SymbolTableList::push()
{
  list.push_back(SymbolTable());
  ++top;
}

bool SymbolTableList::pop()
{
  if (list.size() <= 0) return false; // null
  list.pop_back();
  --top;
  return true;
}

int SymbolTableList::insert(string id, idInfo info)
{
  return list[top].insert(id, info.type, info.flag, info.value, info.init);
}

int SymbolTableList::insert(string id, int type, int start_index, int end_index)
{
  idValue val;
  val.arr_start_index = start_index;
  val.arr_end_index = end_index;
  val.array_val = vector<idInfo>(end_index-start_index+1);
  int size = end_index - start_index + 1;
  for(int i = 0; i < size; i++){
    val.array_val[i].index = -1;
    val.array_val[i].type = type;
    val.array_val[i].flag = variableFlag;
  }
  return list[top].insert(id, arrayType, variableFlag, val, false);
}

idInfo *SymbolTableList::lookup(string id)
{
  for (int i = top; i >= 0; i--) {
    if (list[i].isExist(id)) return list[i].lookup(id);
  }
  return NULL;
}

void SymbolTableList::dump()
{
  cout << "---------- dump start ----------" << endl << endl;
  for (int i = top; i >= 0; --i) {
    cout << "scoped index: " << i << endl;
    list[i].dump();
  }
  cout << "---------- dump end ----------" << endl;
}
void SymbolTableList::setFuncType(int type)
{
  list[top - 1].setFuncType(type);
}

void SymbolTableList::addFuncArg(string id, idInfo info)
{
  list[top - 1].addFuncArg(id, info);
}

/* utilities */

bool isConst(idInfo info)
{
  if (info.flag == constValueFlag || info.flag == constVariableFlag) return true;
  else return false;
}

idInfo *intConst(int val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = intType;
  info->value.int_val = val;
  info->flag = constValueFlag;
  return info;
}

idInfo *realConst(double val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = realType;
  info->value.double_val = val;
  info->flag = constValueFlag;
  return info;
}

idInfo *boolConst(bool val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = boolType;
  info->value.bool_val = val;
  info->flag = constValueFlag;
  return info;
}

idInfo *strConst(string *val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = strType;
  info->value.str_val = *val;
  info->flag = constValueFlag;
  return info;
}
