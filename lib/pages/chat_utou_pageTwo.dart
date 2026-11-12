import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/firebase_options.dart';

class ChatPage extends StatefulWidget {
  /// مفتاح الغرفة تحت ride_chats/ مثل bidding_trip_12
  final String roomId;
  final String partnerId;
  final String currentUserId;
  final String? orderType;
  final int? orderId;

  /// توافق مع الشاشات القديمة التي كانت تمرّر bookingId فقط
  final String? bookingId;

  const ChatPage({
    super.key,
    this.roomId = '',
    this.bookingId,
    required this.partnerId,
    required this.currentUserId,
    this.orderType,
    this.orderId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<types.Message> _messages = [];
  final Map<String, types.Message> _byId = {};
  StreamSubscription<DatabaseEvent>? _messagesSub;
  StreamSubscription<DatabaseEvent>? _legacySub;
  StreamSubscription<DatabaseEvent>? _metaSub;
  DatabaseReference? _messagesRef;
  DatabaseReference? _legacyMessagesRef;
  DatabaseReference? _roomRef;
  bool _isSending = false;
  bool _isReady = false;
  bool _isClosed = false;
  bool _closingShown = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initFirebaseChat();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _legacySub?.cancel();
    _metaSub?.cancel();
    super.dispose();
  }

  String get _chatRoomId {
    final room = widget.roomId.trim();
    if (room.isNotEmpty && room != 'null') return room;
    final booking = (widget.bookingId ?? '').trim();
    if (booking.isNotEmpty && booking != 'null') {
      if (booking.startsWith('ride_') || booking.contains('_')) return booking;
      return 'ride_$booking';
    }
    return '';
  }

  /// غرفة قديمة ride_{id} لو الغرفة الجديدة type_id
  String? get _legacyRoomId {
    final room = _chatRoomId;
    if (room.isEmpty) return null;
    if (room.startsWith('ride_')) return null;
    final parts = room.split('_');
    final id = parts.isNotEmpty ? parts.last : '';
    if (id.isEmpty || int.tryParse(id) == null) return null;
    return 'ride_$id';
  }

  String _formatFirebaseError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return 'تم رفض الوصول.\nافتح Firebase → Realtime Database → Rules\nواسمح بالقراءة والكتابة لـ ride_chats';
    }
    if (message.contains('network') || message.contains('internet')) {
      return 'تحقق من اتصال الإنترنت ثم أعد المحاولة.';
    }
    return 'تعذر الاتصال بقاعدة البيانات.\nتأكد من قواعد Firebase (Rules).';
  }

  Future<void> _ensureFirebaseInitialized() async {
    try {
      Firebase.app();
    } catch (_) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  FirebaseDatabase _openDatabase() {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.databaseUrl,
    );
  }

  Future<void> _onChatClosed() async {
    if (_closingShown || !mounted) return;
    _closingShown = true;
    setState(() => _isClosed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إغلاق المحادثة بعد إنهاء الطلب')),
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).pop();
  }

  void _applySnapshot(DatabaseEvent event) {
    final value = event.snapshot.value;
    if (value is Map) {
      for (final entry in value.entries) {
        final raw = entry.value;
        if (raw is Map) {
          _byId[entry.key.toString()] = _toChatMessage(
            entry.key.toString(),
            Map<String, dynamic>.from(raw),
          );
        }
      }
    }
    final loaded = _byId.values.toList()
      ..sort((a, b) => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0));
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(loaded);
      _initError = null;
    });
  }

  Future<void> _initFirebaseChat() async {
    setState(() {
      _isReady = false;
      _initError = null;
    });

    final roomId = _chatRoomId;
    if (roomId.isEmpty) {
      setState(() {
        _initError = 'تعذر فتح المحادثة: معرّف الطلب غير متاح.';
        _isReady = true;
      });
      return;
    }
    if (widget.currentUserId.trim().isEmpty) {
      setState(() {
        _initError = 'تعذر فتح المحادثة: سجّل الدخول مرة أخرى.';
        _isReady = true;
      });
      return;
    }

    try {
      await _ensureFirebaseInitialized();
      final database = _openDatabase();
      _roomRef = database.ref('ride_chats/$roomId');
      _messagesRef = _roomRef!.child('messages');

      _metaSub = _roomRef!.onValue.listen((event) {
        final value = event.snapshot.value;
        var closed = false;
        if (value is Map) {
          closed = value['isClosed'] == true ||
              value['closed'] == true ||
              value['status']?.toString() == 'completed' ||
              value['status']?.toString() == 'cancelled';
        }
        if (closed) {
          unawaited(_onChatClosed());
        }
      });

      _messagesSub = _messagesRef!.onValue.listen(
        _applySnapshot,
        onError: (error) {
          debugPrint('firebase chat listen error: $error');
          if (!mounted) return;
          setState(() => _initError = _formatFirebaseError(error));
        },
      );

      // اقرأ الغرفة القديمة أيضاً حتى تظهر الرسائل السابقة
      final legacy = _legacyRoomId;
      if (legacy != null) {
        _legacyMessagesRef = database.ref('ride_chats/$legacy/messages');
        _legacySub = _legacyMessagesRef!.onValue.listen(
          _applySnapshot,
          onError: (error) {
            debugPrint('firebase legacy chat listen skipped: $error');
          },
        );
      }

      if (!mounted) return;
      setState(() => _isReady = true);

      unawaited(
        _roomRef!.update({
          'bookingId': roomId,
          'updatedAt': ServerValue.timestamp,
          'participants/${widget.currentUserId}': true,
          if (widget.partnerId.trim().isNotEmpty &&
              widget.partnerId != 'null')
            'participants/${widget.partnerId}': true,
        }).catchError((error) {
          debugPrint('firebase room meta update skipped: $error');
        }),
      );
    } catch (e, stack) {
      debugPrint('firebase chat init error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _initError =
            'تعذر تهيئة المحادثة.\nتأكد من تفعيل Firebase Realtime Database في المشروع.';
        _isReady = true;
      });
    }
  }

  types.TextMessage _toChatMessage(String id, Map<String, dynamic> data) {
    return types.TextMessage(
      id: id,
      author: types.User(id: data['senderId']?.toString() ?? ''),
      createdAt: _parseTimestamp(data['createdAt']),
      text: data['text']?.toString() ?? '',
    );
  }

  int _parseTimestamp(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _notifyPartner(String text) async {
    final partner = widget.partnerId.trim();
    if (partner.isEmpty || partner == 'null') return;
    try {
      final dio = Dio();
      await dio.post(
        chatNotifyPartnerEP,
        data: {
          'partner_id': int.tryParse(partner) ?? partner,
          'text': text,
          'chat_room_id': _chatRoomId,
          if (widget.orderType != null) 'order_type': widget.orderType,
          if (widget.orderId != null) 'order_id': widget.orderId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 600,
        ),
      );
    } catch (e) {
      debugPrint('chat notify partner skipped: $e');
    }
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final text = message.text.trim();
    if (text.isEmpty || _isSending || _messagesRef == null) return;

    if (_isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المحادثة مغلقة بعد إنهاء الطلب')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final payload = {
        'senderId': widget.currentUserId,
        'receiverId': widget.partnerId,
        'text': text,
        'createdAt': ServerValue.timestamp,
      };
      await _messagesRef!.push().set(payload);
      // اكتب أيضاً في الغرفة القديمة للتوافق
      final legacyRef = _legacyMessagesRef;
      if (legacyRef != null) {
        unawaited(Future(() async {
          try {
            await legacyRef.push().set(payload);
          } catch (_) {}
        }));
      }
      unawaited(_notifyPartner(text));
    } catch (e) {
      debugPrint('firebase send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إرسال الرسالة. تحقق من قواعد Firebase.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _initError ?? 'حدث خطأ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initFirebaseChat,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isClosed ? 'المحادثة مغلقة' : 'المحادثة',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : _initError != null
              ? _buildErrorState()
              : _isClosed
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'تم إغلاق المحادثة تلقائيًا بعد إنهاء الطلب',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                        ),
                      ),
                    )
                  : Chat(
                      messages: _messages.reversed.toList(),
                      onSendPressed: _handleSendPressed,
                      user: types.User(id: widget.currentUserId),
                    ),
    );
  }
}
