import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAVhMvSIiVtXzkgeDeChRNOs_WzvI0LkW8',
  authDomain: 'daysthatcount-27055.firebaseapp.com',
  projectId: 'daysthatcount-27055',
  storageBucket: 'daysthatcount-27055.firebasestorage.app',
  messagingSenderId: '715500494673',
  appId: '1:715500494673:web:fbbf5a240f1900b64d7d70',
);

const androidFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAwWBOZKnRO9J0CtEa-WDKmCyvr48kEQeA',
  appId: '1:715500494673:android:89f0ff7a8c6b4f814d7d70',
  messagingSenderId: '715500494673',
  projectId: 'daysthatcount-27055',
  storageBucket: 'daysthatcount-27055.firebasestorage.app',
);

FirebaseOptions get currentFirebaseOptions =>
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? androidFirebaseOptions
        : firebaseOptions;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: currentFirebaseOptions);
  runApp(const DaysThatCountApp());
}

// =====================================================================
// DESIGN SYSTEM
// =====================================================================

class AppColors {
  static const background = Color(0xFFF5F6FA); // cool paper
  static const surface = Colors.white;
  static const ink = Color(0xFF15191C);
  static const textSecondary = Color(0xFF6B7177);
  static const border = Color(0xFFE2E5EE);

  static const primary = Color(0xFF1D3BCB); // cobalt
  static const primarySoft = Color(0xFFE5EAFB);
  static const highlight = Color(0xFFBCD3FF); // sky blue, used sparingly

  static const error = Color(0xFFB3261E);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double md = 14;
  static const double lg = 18;
}

ThemeData buildTheme() {
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: const BorderSide(color: AppColors.border),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
        .copyWith(primary: AppColors.primary, surface: AppColors.surface),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.ink,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.ink,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primarySoft,
      height: 68,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

// =====================================================================
// MODEL + BIRTHDAY LOGIC (day + month only)
// =====================================================================

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];
// February allows 29 because there is no year to check against.
const _daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

String formatShort(DateTime d) => '${d.day} ${_monthShort[d.month - 1]}';
String formatLong(DateTime d) =>
    '${_weekdayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]}';

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
bool isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

String countdownLabel(int days) {
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}

class Birthday {
  const Birthday({
    required this.id,
    required this.name,
    required this.day,
    required this.month,
    this.notes,
  });

  final String id;
  final String name;
  final int day;
  final int month;
  final String? notes;

  factory Birthday.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Birthday(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      day: (d['day'] as num?)?.toInt() ?? 1,
      month: (d['month'] as num?)?.toInt() ?? 1,
      notes: d['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'day': day,
        'month': month,
        if (notes != null) 'notes': notes,
      };

  // Feb 29 birthdays are celebrated on Feb 28 in non-leap years.
  DateTime _dateIn(int y) {
    if (month == 2 && day == 29 && !isLeapYear(y)) {
      return DateTime.utc(y, 2, 28);
    }
    return DateTime.utc(y, month, day);
  }

  DateTime nextOccurrence(DateTime today) {
    final t = dateOnly(today);
    var d = _dateIn(t.year);
    if (d.isBefore(t)) d = _dateIn(t.year + 1);
    return d;
  }

  int daysUntil(DateTime today) =>
      nextOccurrence(today).difference(dateOnly(today)).inDays;

  String get dateLabel => '$day ${_monthNames[month - 1]}';
}

/// Birthdays stored in Firestore at users/{uid}/birthdays, updated live.
class BirthdayStore extends ChangeNotifier {
  List<Birthday> _items = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;
  bool loading = true;
  String? error;

  List<Birthday> get all => List.unmodifiable(_items);

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('birthdays');
  }

  /// Start listening to this user's birthdays.
  void listen(String uid) {
    if (_uid == uid) return;
    _sub?.cancel();
    _uid = uid;
    _items = [];
    loading = true;
    error = null;
    notifyListeners();
    _sub = _col.snapshots().listen(
      (snap) {
        _items = snap.docs.map(Birthday.fromDoc).toList();
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[store] listen error: $e');
        loading = false;
        error = "We couldn't load your birthdays. Check your connection and try again.";
        notifyListeners();
      },
    );
  }

  /// Stop listening (used on log out).
  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    _items = [];
    loading = true;
    error = null;
    notifyListeners();
  }

  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _uid = null;
    listen(uid);
  }

  /// Completes once the first load (or load error) has finished.
  Future<void> whenLoaded() async {
    if (!loading) return;
    final c = Completer<void>();
    void check() {
      if (!loading && !c.isCompleted) {
        removeListener(check);
        c.complete();
      }
    }

    addListener(check);
    await c.future;
  }

  Birthday? byId(String id) {
    for (final b in _items) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<Birthday> sortedUpcoming() {
    final today = dateOnly(DateTime.now());
    final list = [..._items];
    list.sort((a, b) => a.daysUntil(today).compareTo(b.daysUntil(today)));
    return list;
  }

  bool exists(String name, int day, int month, {String? ignoreId}) {
    final n = name.trim().toLowerCase();
    return _items.any((b) =>
        b.id != ignoreId &&
        b.name.trim().toLowerCase() == n &&
        b.day == day &&
        b.month == month);
  }

  Future<void> add(Birthday b) async {
    await _col.add({...b.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> update(Birthday b) async {
    await _col.doc(b.id).update({
      'name': b.name,
      'day': b.day,
      'month': b.month,
      'notes': b.notes ?? FieldValue.delete(),
    });
  }

  Future<void> remove(String id) async {
    await _col.doc(id).delete();
  }
}

final store = BirthdayStore();

// =====================================================================
// SHARING LINKS (Firestore: links/{token} and links/{token}/submissions)
// =====================================================================

class LinkService {
  // The public page that people open. We create it in the next step.
  static const baseUrl = 'https://ashbornmusashi.github.io/DaysThatCount/';

  static String urlFor(String token) => '$baseUrl?t=$token';

  static String _newToken() {
    final r = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Returns the user's active link, creating one if there isn't any.
  static Future<String> getOrCreateActiveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final db = FirebaseFirestore.instance;

    final existing = await db
        .collection('links')
        .where('ownerId', isEqualTo: user.uid)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final token = _newToken();
    final name = (user.displayName ?? '').trim();
    await db.collection('links').doc(token).set({
      'ownerId': user.uid,
      'ownerName': name.isEmpty ? 'a friend' : name,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return token;
  }

  static Future<void> deactivate(String token) async {
    await FirebaseFirestore.instance
        .collection('links')
        .doc(token)
        .update({'active': false});
  }
}

/// Watches the user's links. Anything people submit through them is moved
/// into the user's birthdays automatically.
class LinkImporter {
  String? _uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _linksSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _subs = {};
  final Set<String> _busy = {};
  final Set<String> _recent = {};

  void start(String uid) {
    if (_uid == uid) return;
    stop();
    _uid = uid;
    debugPrint('[importer] started for $uid');
    _linksSub = FirebaseFirestore.instance
        .collection('links')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      debugPrint('[importer] your links: ${snap.docs.length}');
      for (final doc in snap.docs) {
        if (_subs.containsKey(doc.id)) continue;
        _subs[doc.id] = doc.reference.collection('submissions').snapshots().listen(
          (subSnap) {
            debugPrint('[importer] submissions waiting on ${doc.id}: ${subSnap.docs.length}');
            for (final sub in subSnap.docs) {
              _import(uid, sub);
            }
          },
          onError: (e) => debugPrint('[importer] submissions error: $e'),
        );
      }
    }, onError: (e) => debugPrint('[importer] links error: $e'));
  }

  void stop() {
    _linksSub?.cancel();
    _linksSub = null;
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _busy.clear();
    _recent.clear();
    _uid = null;
  }

  Future<void> _import(
    String uid,
    QueryDocumentSnapshot<Map<String, dynamic>> sub,
  ) async {
    final path = sub.reference.path;
    if (!_busy.add(path)) return;
    String? key;
    try {
      await store.whenLoaded();
      if (_uid != uid) return;

      final d = sub.data();
      debugPrint('[importer] importing: $d');
      final name = ((d['name'] as String?) ?? '').trim();
      final day = (d['day'] as num?)?.toInt() ?? 0;
      final month = (d['month'] as num?)?.toInt() ?? 0;
      key = '${name.toLowerCase()}|$day|$month';

      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      if (name.isNotEmpty && !store.exists(name, day, month) && _recent.add(key)) {
        final ref = db.collection('users').doc(uid).collection('birthdays').doc();
        batch.set(ref, {
          'name': name,
          'day': day,
          'month': month,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      batch.delete(sub.reference);
      await batch.commit();
      debugPrint('[importer] imported OK: $name $day/$month');
    } catch (e) {
      debugPrint('[importer] import FAILED: $e');
      // Leave it in place; we'll try again next time the app opens.
    } finally {
      if (key != null) _recent.remove(key);
      _busy.remove(path);
    }
  }
}

final importer = LinkImporter();

// =====================================================================
// APP + NAVIGATION SHELL (3 tabs)
// =====================================================================

class DaysThatCountApp extends StatelessWidget {
  const DaysThatCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Days That Count',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

// =====================================================================
// AUTH (Firebase email + password)
// =====================================================================

/// Shows the login screen when signed out and the app when signed in.
/// Also starts/stops loading the user's birthdays.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        importer.stop();
        store.stop();
      } else {
        store.listen(user.uid);
        importer.start(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) return const AuthScreen();
        return const MainShell();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "That email address doesn't look right.";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a little and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is switched off in Firebase.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      final password = _password.text;
      if (_isSignUp) {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await cred.user?.updateDisplayName(_name.text.trim());
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter your email above first, then tap "Forgot password?"');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.cake_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Days That Count',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'So you never forget.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isSignUp) ...[
                      const _FieldLabel('Your name'),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'e.g. Thandi'),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return 'Please enter your name';
                          if (t.length > 60) return 'Name is too long';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const _FieldLabel('Email'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Password'),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEBEA),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isSignUp ? 'Create account' : 'Log in'),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _error = null;
                                }),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Log in'
                              : 'New here? Create an account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onAdd: () => setState(() => _index = 1)),
          const AddScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon:
                Icon(Icons.add_circle_rounded, color: AppColors.primary),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon:
                Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// REUSABLE WIDGETS
// =====================================================================

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  static const _backgrounds = [
    AppColors.primarySoft,
    Color(0xFFDCEBFA),
    Color(0xFFE6E8EE),
    Color(0xFFF1E4E4),
  ];
  static const _foregrounds = [
    AppColors.primary,
    Color(0xFF2A6FB0),
    Color(0xFF475069),
    Color(0xFF8A3B3B),
  ];

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    final initials = parts.map((p) => p[0].toUpperCase()).join();
    final i = name.codeUnits.fold<int>(0, (a, c) => a + c) % 4;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _backgrounds[i], shape: BoxShape.circle),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: _foregrounds[i],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class SmallLabel extends StatelessWidget {
  const SmallLabel(this.text, {super.key, this.color = AppColors.textSecondary});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: color,
      ),
    );
  }
}

class CountdownPill extends StatelessWidget {
  const CountdownPill({super.key, required this.days, this.isToday = false});
  final int days;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? AppColors.highlight : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        countdownLabel(days),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isToday ? AppColors.ink : AppColors.primary,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void openDetail(BuildContext context, Birthday b) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BirthdayDetailScreen(birthdayId: b.id)),
  );
}

class BirthdayTile extends StatelessWidget {
  const BirthdayTile({
    super.key,
    required this.birthday,
    required this.today,
  });

  final Birthday birthday;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = birthday.daysUntil(today);
    final isToday = days == 0;
    final next = birthday.nextOccurrence(today);
    final subtitle = '${_weekdayNames[next.weekday - 1]}, ${formatShort(next)}';

    return AppCard(
      onTap: () => openDetail(context, birthday),
      color: isToday ? AppColors.primary : AppColors.surface,
      borderColor: isToday ? AppColors.primary : AppColors.border,
      child: Row(
        children: [
          Avatar(name: birthday.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  birthday.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isToday
                        ? const Color(0xB3FFFFFF)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CountdownPill(days: days, isToday: isToday),
        ],
      ),
    );
  }
}

// =====================================================================
// HOME: next birthday + search + everyone grouped by month
// =====================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Widget> _monthGroups(List<Birthday> list, DateTime today) {
    final widgets = <Widget>[];
    String? lastKey;
    for (final b in list) {
      final next = b.nextOccurrence(today);
      final key = '${next.year}-${next.month}';
      if (key != lastKey) {
        lastKey = key;
        final month = _monthNames[next.month - 1];
        final label = next.year == today.year ? month : '$month ${next.year}';
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 22, bottom: 10),
            child: SmallLabel(label),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: BirthdayTile(birthday: b, today: today),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            if (store.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (store.error != null) {
              return EmptyState(
                icon: Icons.cloud_off_rounded,
                title: "Couldn't load birthdays",
                message: store.error!,
                actionLabel: 'Try again',
                onAction: store.retry,
              );
            }
            if (store.all.isEmpty) {
              return EmptyState(
                icon: Icons.cake_outlined,
                title: 'No birthdays yet',
                message: 'Add your first birthday so you never forget.',
                actionLabel: 'Add a birthday',
                onAction: widget.onAdd,
              );
            }

            final today = dateOnly(DateTime.now());
            final sorted = store.sortedUpcoming();
            final searching = _query.isNotEmpty;
            final matches = sorted
                .where((b) => b.name.toLowerCase().contains(_query))
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatLong(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onAdd,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.add_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search birthdays',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searching
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
                if (!searching) ...[
                  const SizedBox(height: 16),
                  NextBirthdayCard(birthday: sorted.first, today: today),
                  const SizedBox(height: 28),
                  const SmallLabel('Everyone'),
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 20),
                if (matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No matches',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ..._monthGroups(matches, today),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NextBirthdayCard extends StatelessWidget {
  const NextBirthdayCard({
    super.key,
    required this.birthday,
    required this.today,
  });

  final Birthday birthday;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = birthday.daysUntil(today);
    final isToday = days == 0;
    final next = birthday.nextOccurrence(today);

    final bg = isToday ? AppColors.highlight : AppColors.primary;
    final fg = isToday ? AppColors.ink : Colors.white;
    final muted = isToday ? const Color(0xB315191C) : const Color(0xB3FFFFFF);
    final accent = isToday ? AppColors.ink : AppColors.highlight;

    return GestureDetector(
      onTap: () => openDetail(context, birthday),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SmallLabel(
                  isToday ? 'Today' : 'Next birthday',
                  color: accent,
                ),
                const Spacer(),
                Text(
                  formatShort(next),
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              birthday.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 20),
            if (isToday)
              Text(
                'Send your wishes today.',
                style: TextStyle(color: muted, fontSize: 15),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$days',
                    style: TextStyle(
                      color: accent,
                      fontSize: 60,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      days == 1 ? 'day to go' : 'days to go',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// ADD TAB (manual or request link)
// =====================================================================

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  void _showLinkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const LinkSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a birthday')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'How would you like to add it?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.edit_calendar_rounded,
            title: 'Add manually',
            subtitle: 'Type in a name and date yourself.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddBirthdayScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.link_rounded,
            title: 'Request via link',
            subtitle: 'Send a link. They fill in their own birthday.',
            onTap: () => _showLinkSheet(context),
          ),
        ],
      ),
    );
  }
}

class LinkSheet extends StatefulWidget {
  const LinkSheet({super.key});

  @override
  State<LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<LinkSheet> {
  String? _token;
  String? _url;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await LinkService.getOrCreateActiveToken();
      if (!mounted) return;
      setState(() {
        _token = token;
        _url = LinkService.urlFor(token);
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't create your link. Check your connection and try again.";
      });
    }
  }

  Future<void> _turnOff() async {
    final token = _token;
    if (token == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await LinkService.deactivate(token);
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Link turned off. A new one is made next time.')),
      );
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't turn it off. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your sharing link',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send this to friends or family. They enter their name and birthday, '
            'and it appears in your list automatically. They can\'t see anything else.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              child: const Text('Try again'),
            ),
          ] else if (url == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied. Paste it into WhatsApp or SMS.')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: const Text('Copy link'),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _turnOff,
                child: const Text(
                  'Turn off this link',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// =====================================================================
// ADD / EDIT FORM (name, month + day, notes)
// =====================================================================

class AddBirthdayScreen extends StatefulWidget {
  const AddBirthdayScreen({super.key, this.existing});
  final Birthday? existing;

  @override
  State<AddBirthdayScreen> createState() => _AddBirthdayScreenState();
}

class _AddBirthdayScreenState extends State<AddBirthdayScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  int? _month;
  int? _day;
  String? _dateError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _month = e.month;
      _day = e.day;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    setState(() {
      _dateError =
          (_month == null || _day == null) ? 'Please choose a month and day' : null;
    });
    if (!formOk || _month == null || _day == null) return;

    final name = _name.text.trim();
    final existing = widget.existing;
    if (store.exists(name, _day!, _month!, ignoreId: existing?.id)) {
      setState(() => _dateError = 'You already saved $name with this date');
      return;
    }

    final notes = _notes.text.trim();
    final b = Birthday(
      id: existing?.id ?? '',
      name: name,
      day: _day!,
      month: _month!,
      notes: notes.isEmpty ? null : notes,
    );

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final op = existing == null ? store.add(b) : store.update(b);
      await op.timeout(const Duration(seconds: 10));
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(existing == null ? '$name added' : 'Changes saved')),
      );
    } on TimeoutException {
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text("Saved. It will sync when you're back online.")),
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final maxDay = _month == null ? 31 : _daysInMonth[_month! - 1];

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit birthday' : 'New birthday')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo upload arrives with the backend'),
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _name,
                        builder: (_, __) => Avatar(name: _name.text, size: 96),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Name'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Nomsa Dlamini'),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Please enter a name';
                  if (t.length > 80) return 'Name is too long';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Birthday'),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InputDecorator(
                      isEmpty: _month == null,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _month,
                          isExpanded: true,
                          hint: const Text('Month'),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem<int>(
                              value: i + 1,
                              child: Text(_monthNames[i]),
                            ),
                          ),
                          onChanged: (v) => setState(() {
                            _month = v;
                            _dateError = null;
                            if (v != null &&
                                _day != null &&
                                _day! > _daysInMonth[v - 1]) {
                              _day = null;
                            }
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: InputDecorator(
                      isEmpty: _day == null,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _day,
                          isExpanded: true,
                          hint: const Text('Day'),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          items: List.generate(
                            maxDay,
                            (i) => DropdownMenuItem<int>(
                              value: i + 1,
                              child: Text('${i + 1}'),
                            ),
                          ),
                          onChanged: (v) => setState(() {
                            _day = v;
                            _dateError = null;
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_dateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _dateError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              const _FieldLabel('Notes (optional)'),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Gift ideas, favourite cake...',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(editing ? 'Save changes' : 'Save birthday'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// =====================================================================
// DETAIL SCREEN
// =====================================================================

class BirthdayDetailScreen extends StatelessWidget {
  const BirthdayDetailScreen({super.key, required this.birthdayId});
  final String birthdayId;

  Future<void> _confirmDelete(BuildContext context, Birthday b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete birthday?'),
        content: Text('${b.name} will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      try {
        await store.remove(b.id).timeout(const Duration(seconds: 10));
        messenger.showSnackBar(SnackBar(content: Text('${b.name} deleted')));
      } on TimeoutException {
        messenger.showSnackBar(
          const SnackBar(content: Text("Deleted. It will sync when you're back online.")),
        );
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't delete. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final b = store.byId(birthdayId);
        if (b == null) return const Scaffold();

        final today = dateOnly(DateTime.now());
        final days = b.daysUntil(today);
        final next = b.nextOccurrence(today);

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddBirthdayScreen(existing: b),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _confirmDelete(context, b),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Center(child: Avatar(name: b.name, size: 96)),
              const SizedBox(height: 16),
              Text(
                b.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        value: days == 0 ? 'Today' : '$days',
                        label: days == 0
                            ? 'Happy birthday'
                            : (days == 1 ? 'day to go' : 'days to go'),
                      ),
                    ),
                    Container(width: 1, height: 44, color: AppColors.border),
                    Expanded(
                      child: _Stat(
                        value: formatShort(next),
                        label: _weekdayNames[next.weekday - 1],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SmallLabel('Birthday'),
                    const SizedBox(height: 6),
                    Text(
                      b.dateLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (b.notes != null) ...[
                      const SizedBox(height: 16),
                      const SmallLabel('Notes'),
                      const SizedBox(height: 6),
                      Text(b.notes!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// =====================================================================
// SETTINGS
// =====================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _onDay = true;
  final Set<int> _daysBefore = {7, 1};
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  static const _options = [1, 2, 3, 7, 14];

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
              final name = (user?.displayName ?? '').trim();
              final email = user?.email ?? '';
              final shownName =
                  name.isNotEmpty ? name : (email.isNotEmpty ? email : 'You');
              return AppCard(
                child: Row(
                  children: [
                    Avatar(name: shownName, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shownName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SectionTitle('Reminders'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Remind me on the day',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _onDay,
                  onChanged: (v) => setState(() => _onDay = v),
                ),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                const Text(
                  'Also remind me before (up to 3)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in _options)
                      FilterChip(
                        label: Text(d == 1 ? '1 day' : '$d days'),
                        selected: _daysBefore.contains(d),
                        showCheckmark: false,
                        selectedColor: AppColors.primarySoft,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _daysBefore.contains(d)
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _daysBefore.contains(d)
                              ? AppColors.primary
                              : AppColors.ink,
                        ),
                        onSelected: (v) {
                          if (v && _daysBefore.length >= 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You can choose up to 3'),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            v ? _daysBefore.add(d) : _daysBefore.remove(d);
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Reminder time',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    _time.format(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Days That Count\nSo you never forget.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
