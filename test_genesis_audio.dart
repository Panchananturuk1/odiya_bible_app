import 'package:flutter/material.dart';
import 'lib/services/json_bible_service.dart';
import 'lib/services/usx_parser.dart';

void main() {
  // Test the book name conversion for Genesis
  print('=== Testing Genesis Book Name Conversion ===');
  
  // Test book ID 1 (Genesis) conversion
  int genesisBookId = 1;
  String bookName = JsonBibleService.getBookNameById(genesisBookId);
  print('Book ID $genesisBookId -> Book Name: "$bookName"');
  
  // Test USX code conversion
  String? usxCode = USXParser.getUSXCodeFromBookName(bookName);
  print('Book Name "$bookName" -> USX Code: "$usxCode"');
  
  // Test a few more Old Testament books
  print('\n=== Testing Other OT Books ===');
  for (int bookId = 1; bookId <= 5; bookId++) {
    String name = JsonBibleService.getBookNameById(bookId);
    String? code = USXParser.getUSXCodeFromBookName(name);
    print('Book ID $bookId: "$name" -> "$code"');
  }
  
  // Test New Testament for comparison
  print('\n=== Testing NT Books for Comparison ===');
  for (int bookId = 40; bookId <= 44; bookId++) {
    String name = JsonBibleService.getBookNameById(bookId);
    String? code = USXParser.getUSXCodeFromBookName(name);
    print('Book ID $bookId: "$name" -> "$code"');
  }
}