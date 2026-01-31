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

  // Create a new agent
  Future<String> createAgent(Agent agent) async {
    try {
      final docRef = await _firestore.collection(_collection).add(agent.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'Error creating agent: $e';
    }
  }

  // Update agent
  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(agentId).update(data);
    } catch (e) {
      throw 'Error updating agent: $e';
    }
  }

  // Get agent by user ID
  Future<Agent?> getAgentByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return Agent.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw 'Error fetching agent by user ID: $e';
    }
  }
}
