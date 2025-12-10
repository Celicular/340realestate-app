import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agent.dart';

class AgentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'agents';

  // Get all agents
  Future<List<Agent>> getAllAgents() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();
      return snapshot.docs.map((doc) => Agent.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching agents: $e';
    }
  }

  // Get agent by ID
  Future<Agent?> getAgentById(String agentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(agentId).get();
      if (doc.exists) {
        return Agent.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error fetching agent: $e';
    }
  }

  // Get top agents
  Future<List<Agent>> getTopAgents({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => Agent.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching top agents: $e';
    }
  }
}
