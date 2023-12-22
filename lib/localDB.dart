
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


// Singleton class for managing local database operations
class LocalDatabaseHelper {
  // Singleton instance
  static final LocalDatabaseHelper _instance = LocalDatabaseHelper._internal();

  // Factory constructor to provide a single instance
  factory LocalDatabaseHelper() {
    return _instance;
  }

  // Private constructor for enforcing singleton pattern
  LocalDatabaseHelper._internal();

  // Reference to the SQLite database
  static Database? _database;

  // Getter to access the database asynchronously
  Future<Database> get database async {
    // If the database is already initialized, return it
    if (_database != null) return _database!;

    // If the database is not initialized, initialize and return it
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database and create tables
  Future<Database> _initDatabase() async {
    // Define the path for the SQLite database file
    String path = join(await getDatabasesPath(), 'my_db.db');

    // Open the database or create a new one if it doesn't exist
    return await openDatabase(path, version: 1, onCreate: _createTable);
  }

  // Create the profile table in the database
  Future<void> _createTable(Database db, int version) async {
    await db.execute(_createProfileTableSQL);
  }

  // Insert data into the 'my_profile' table
  Future<void> insertData(Map<String, dynamic> data) async {
    Database db = await database;

    // Check if the 'my_profile' table exists
    var tables = await db
        .query('sqlite_master', where: 'name = ?', whereArgs: ['my_profile']);

    if (tables.isEmpty) {
      // If the table doesn't exist, create it
      await _createTable(db, 1);
    }

    // Insert data into the 'my_profile' table
    await db.insert('my_profile', data);
  }

  // Fetch all data from the 'my_profile' table
  Future<List<Map<String, dynamic>>> getData(String text) async {
    Database db = await database;
    return await db.query('my_profile');
  }

  // Fetch profile data for a specific email from the 'my_profile' table
  Future<LocalUser?> getDataForEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'my_profile',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return LocalUser.fromMap(result.first);
    } else {
      return LocalUser(
        fullName: "",
        phoneNumber: "",
        email: "",
        password: "",

      );
    }
  }

  // Fetch profile image path for a specific email from the 'my_profile' table
  Future<String?> getProfileImgByEmail(String email) async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'my_profile',
      columns: ['profileImgPath'],
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return result[0]['profileImgPath'] as String?;
    } else {
      return null; // Email not found in the database
    }
  }

  // Delete data for a specific email from the 'my_profile' table
  Future<int> deleteData(String email) async {
    Database db = await database;
    return await db
        .delete('my_profile', where: 'email = ?', whereArgs: [email]);
  }

  // Delete the 'my_profile' table and recreate it
  Future<void> deleteTable() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS my_profile');
    await _createTable(db, 1); // Recreate the table after deletion
  }
}

// Model class representing a user profile
class LocalUser {
  int? id;
  String fullName;
  String phoneNumber;
  String email;
  String password;


  LocalUser({
    this.id,

    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,

  });

  // Convert user profile data to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,

    };
  }

  // Create a user profile object from a map
  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'],
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',

    );
  }
}

// SQL query to create the 'my_profile' table
const String _createProfileTableSQL = '''
  CREATE TABLE my_profile (
  id INTEGER AUTO_INCREMENT,
   fullName VARCHAR(100) NOT NULL,
  phoneNumber VARCHAR(20) NOT NULL,
    email VARCHAR(255) PRIMARY KEY NOT NULL,
  password VARCHAR(255) NOT NULL,

  )
''';