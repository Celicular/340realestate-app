import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/agent.dart';
import '../models/team_member.dart';
import '../models/user.dart' as app_user;
import 'package:url_launcher/url_launcher.dart';

class AgentsPage extends StatefulWidget {
  const AgentsPage({super.key});

  @override
  State<AgentsPage> createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  final List<Agent> _agents = [];
  final int _pageSize = 10;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInitial();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchInitial() async {
    try {
      // Try agents with status filter
      Query agentsQuery = FirebaseFirestore.instance
          .collection('agents')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      QuerySnapshot snapshot;
      try {
        snapshot = await agentsQuery.get();
      } catch (_) {
        // Fallback: try without status filter (avoids composite index requirement)
        agentsQuery = FirebaseFirestore.instance
            .collection('agents')
            .orderBy('createdAt', descending: true)
            .limit(_pageSize);
        snapshot = await agentsQuery.get();
      }
      _agents.addAll(snapshot.docs.map((d) => Agent.fromFirestore(d)).toList());
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      if (snapshot.docs.length < _pageSize) _hasMore = false;
      if (_agents.isEmpty) {
        final tmSnapshot = await FirebaseFirestore.instance
            .collection('team_members')
            .orderBy('createdAt', descending: true)
            .limit(_pageSize)
            .get();
        final team =
            tmSnapshot.docs.map((d) => TeamMember.fromFirestore(d)).toList();
        _agents.addAll(team.map((t) => Agent(
              id: t.id,
              name: t.name,
              email: t.email,
              phone: t.phone,
              profileImage: t.image.isNotEmpty ? t.image : null,
              bio: t.bio,
              title: t.title,
              createdAt: t.createdAt,
            )));
        if (tmSnapshot.docs.isNotEmpty) _lastDoc = tmSnapshot.docs.last;
        _hasMore = tmSnapshot.docs.length == _pageSize;
        // Further fallback: users with role 'agent'
        if (_agents.isEmpty) {
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'agent')
              .orderBy('createdAt', descending: true)
              .limit(_pageSize)
              .get();
          final users = usersSnapshot.docs
              .map((d) => app_user.User.fromFirestore(d))
              .toList();
          _agents.addAll(users.map((u) => Agent(
                id: u.uid,
                name: (u.name.isNotEmpty ? u.name : u.displayName),
                email: u.email,
                phone: u.phoneNumber,
                profileImage: u.photoUrl,
                bio: null,
                title: 'Agent',
                createdAt: u.createdAt,
              )));
          if (usersSnapshot.docs.isNotEmpty) _lastDoc = usersSnapshot.docs.last;
          _hasMore = usersSnapshot.docs.length == _pageSize;
        }
      }
    } catch (_) {}
    _pinPreferredAgent();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final query = FirebaseFirestore.instance
          .collection('agents')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize);
      final snapshot = await query.get();
      _agents.addAll(snapshot.docs.map((d) => Agent.fromFirestore(d)).toList());
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      if (snapshot.docs.length < _pageSize) _hasMore = false;
    } catch (_) {}
    _pinPreferredAgent();
    setState(() => _isLoadingMore = false);
  }

  void _pinPreferredAgent() {
    if (_agents.isEmpty) return;
    final i = _agents.indexWhere(
      (a) => a.name.trim().toLowerCase() == 'tammy donnelly',
    );
    if (i > 0) {
      final a = _agents.removeAt(i);
      _agents.insert(0, a);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet Our Team'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _agents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 80,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No agents found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add data in collections: agents, team_members, or users(role=agent).',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _agents.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _agents.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final agent = _agents[index];
                    return _buildAgentCard(context, agent);
                  },
                ),
    );
  }

  Widget _buildAgentCard(BuildContext context, Agent agent) {
    final expanded = ValueNotifier<bool>(false);
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(agent.name),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (agent.title != null)
                      Text(
                        agent.title!,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      agent.bio ?? 'No details available',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.textTertiary.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: agent.profileImage != null
                            ? NetworkImage(agent.profileImage!)
                            : null,
                        child: agent.profileImage == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (agent.title != null)
                              Text(
                                agent.title!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (agent.bio != null) ...[
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: expanded,
                      builder: (context, isExpanded, _) {
                        return Text(
                          agent.bio!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                          maxLines: isExpanded ? null : 3,
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            expanded.value = !expanded.value;
                          });
                        },
                        child: ValueListenableBuilder<bool>(
                          valueListenable: expanded,
                          builder: (context, isExpanded, _) {
                            return Text(isExpanded ? 'Show less' : 'Show more');
                          },
                        ),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: agent.phone != null && agent.phone!.isNotEmpty
                              ? () async {
                                  final phoneUri = Uri(scheme: 'tel', path: agent.phone!);
                                  if (await canLaunchUrl(phoneUri)) {
                                    await launchUrl(phoneUri);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Unable to open phone dialer'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: agent.email != null && agent.email!.isNotEmpty
                              ? () async {
                                  final emailUri = Uri(
                                    scheme: 'mailto',
                                    path: agent.email!,
                                    query: 'subject=Property Inquiry',
                                  );
                                  if (await canLaunchUrl(emailUri)) {
                                    await launchUrl(emailUri);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Unable to open email app'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text('Email'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
