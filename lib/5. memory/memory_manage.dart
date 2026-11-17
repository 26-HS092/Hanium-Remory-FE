part of 'memory_add_flow.dart';

// 올린 추억을 보고, 고치고, 지운다.
//
// 인형은 몇 분마다 서버의 추억을 받아 기억을 다시 맞춘다. 여기서 고치거나
// 지운 것도 그때 인형에 반영된다(device/rag/rag_sync.py).

/// 올린 추억 목록. 같은 어르신의 가족이 올린 것까지 모두 보인다.
class MemoryListScreen extends StatefulWidget {
  const MemoryListScreen({super.key, this.api});

  /// 테스트에서 바꿔 끼운다.
  final SettingsApi? api;

  @override
  State<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends State<MemoryListScreen> {
  late final SettingsApi _api = widget.api ?? SettingsApi();
  List<MemoryItem>? _items;
  String? _error;

  /// 연결된 어르신. 새 사진을 올릴 때 주인으로 적는다.
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final user = (await _api.myProfile()).mainUser;
      if (user == null) {
        throw ApiException('연결된 어르신이 없어요.', 400);
      }
      final items = await _api.memories(user.userId);
      if (mounted) {
        setState(() {
          _userId = user.userId;
          _items = items;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '추억을 불러오지 못했어요.');
    }
  }

  Future<void> _open(MemoryItem item) async {
    final changed = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            MemoryEditScreen(memory: item, userId: _userId, api: _api),
      ),
    );
    if (changed == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(changed), behavior: SnackBarBehavior.floating),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              _Header(
                title: '올린 추억',
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: _headerGap),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return _Centered(
        text: _error!,
        action: TextButton(
          onPressed: _load,
          child: const Text(
            '다시 불러오기',
            style: TextStyle(color: _brown, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }
    if (items.isEmpty) {
      return const _Centered(text: '아직 올린 추억이 없어요.');
    }
    return RefreshIndicator(
      color: _brown,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: 24.h),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (_, i) =>
            _MemoryTile(item: items[i], onTap: () => _open(items[i])),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.item, required this.onTap});

  final MemoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    final sub = [
      if (item.period != null && item.period!.isNotEmpty) item.period!,
      if (item.description != null && item.description!.isNotEmpty)
        item.description!,
    ].join(' · ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 80.w,
                  height: 48.w, // 인형 화면 비율 5:3
                  child: url == null || url.isEmpty
                      ? Container(
                          color: _softYellow,
                          child: Icon(
                            Icons.notes_outlined,
                            size: 20.sp,
                            color: _brown,
                          ),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: _line,
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 20.sp,
                              color: _muted,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _dark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _caption(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22.sp, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// 추억 하나를 고치거나 지운다. 끝나면 목록에 띄울 한 줄을 돌려준다.
class MemoryEditScreen extends StatefulWidget {
  const MemoryEditScreen({
    super.key,
    required this.memory,
    this.userId,
    this.api,
  });

  final MemoryItem memory;

  /// 사진의 주인이 될 어르신. 새 추억을 올릴 때와 같게 적는다.
  final int? userId;
  final SettingsApi? api;

  @override
  State<MemoryEditScreen> createState() => _MemoryEditScreenState();
}

class _MemoryEditScreenState extends State<MemoryEditScreen> {
  static const _whenOptions = ['오늘', '최근', '몇 년 전', '오래된 기억'];

  late final SettingsApi _api = widget.api ?? SettingsApi();
  late final TextEditingController _title = TextEditingController(
    text: widget.memory.title,
  );
  late final TextEditingController _story = TextEditingController(
    text: widget.memory.description ?? '',
  );

  /// 칩에 없는 말('1980년대' 같은)로 저장된 추억이면 -1. 칩을 누르지 않으면
  /// 원래 값을 그대로 둔다.
  late int _when = _whenOptions.indexOf(widget.memory.period ?? '');
  PreparedPhoto? _newPhoto;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _story.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickPhoto() async {
    final photo = await pickPhotoForDoll(context);
    if (photo == null || !mounted) return;
    setState(() => _newPhoto = photo);
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _title.text.trim();
    if (title.isEmpty) {
      _snack('한 줄 제목을 적어주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      final photo = _newPhoto;
      final uploaded = photo == null
          ? null
          : await _api.uploadPhoto(
              bytes: photo.bytes,
              filename: photo.filename,
              original: photo.original,
              userId: widget.userId,
            );
      await _api.updateMemory(
        widget.memory.memoryId,
        imageUrl: uploaded?.imageUrl,
        originalImageUrl: uploaded?.originalUrl,
        title: title,
        // 칩을 고르지 않았으면 보내지 않아 원래 값을 둔다.
        period: _when >= 0 ? _whenOptions[_when] : null,
        description: _story.text.trim(),
      );
      if (mounted) Navigator.of(context).pop('고쳤어요. 인형에는 몇 분 뒤에 반영돼요.');
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('저장하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          '이 추억을 지울까요?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          '지우면 되돌릴 수 없어요.\n인형도 몇 분 뒤부터 이 추억을 꺼내지 않아요.',
          style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '지우기',
              style: TextStyle(color: _danger, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _api.deleteMemory(widget.memory.memoryId);
      if (mounted) Navigator.of(context).pop('추억을 지웠어요.');
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('지우지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              _Header(
                title: '추억 고치기',
                actionText: _busy ? '저장 중…' : '저장',
                onAction: _busy ? null : _save,
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: _headerGap),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PhotoUploadBox(
                        imageBytes: _newPhoto?.bytes,
                        imageUrl: widget.memory.imageUrl,
                        onTap: _pickPhoto,
                      ),
                      SizedBox(height: 18.h),
                      const _Label('한 줄 제목'),
                      _TextFieldBox(
                        controller: _title,
                        hintText: '예: 손주 운동회',
                        maxLines: 1,
                      ),
                      SizedBox(height: 18.h),
                      const _Label('언제 기억인가요'),
                      if (_when < 0 &&
                          (widget.memory.period ?? '').isNotEmpty) ...[
                        Text(
                          '지금: ${widget.memory.period}',
                          style: _caption(),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          for (var i = 0; i < _whenOptions.length; i++) ...[
                            if (i > 0) SizedBox(width: 6.w),
                            Expanded(
                              child: _ChipButton(
                                text: _whenOptions[i],
                                selected: _when == i,
                                onTap: () => setState(() => _when = i),
                                fill: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 18.h),
                      const _Label('나눌 이야기'),
                      _TextFieldBox(
                        controller: _story,
                        hintText: '그날 있었던 일을 짧고 따뜻하게 적어주세요.',
                        maxLines: 6,
                      ),
                      SizedBox(height: 28.h),
                      Center(
                        child: TextButton.icon(
                          onPressed: _busy ? null : _delete,
                          style: TextButton.styleFrom(
                            foregroundColor: _danger,
                          ),
                          icon: Icon(Icons.delete_outline, size: 18.sp),
                          label: Text(
                            '이 추억 지우기',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const Color _danger = Color(0xFFC0473A);
