class JointConfig {
  final String id;
  final String name;
  final String channel;
  final double minAngle;
  final double maxAngle;
  final double defaultAngle;

  const JointConfig({
    required this.id,
    required this.name,
    required this.channel,
    this.minAngle = 0,
    this.maxAngle = 180,
    this.defaultAngle = 90,
  });

  static const List<JointConfig> defaultJoints = [
    JointConfig(
      id: 'J1',
      name: 'Base Rotation',
      channel: 'CH0',
      minAngle: 0,
      maxAngle: 180,
      defaultAngle: 90,
    ),
    JointConfig(
      id: 'J2',
      name: 'Shoulder',
      channel: 'CH1',
      minAngle: 100,
      maxAngle: 150,
      defaultAngle: 100,
    ),
    JointConfig(
      id: 'J3',
      name: 'Elbow',
      channel: 'CH2',
      minAngle: 0,
      maxAngle: 90,
      defaultAngle: 0,
    ),
    JointConfig(
      id: 'J4',
      name: 'Wrist',
      channel: 'CH3',
      minAngle: 0,
      maxAngle: 180,
      defaultAngle: 0,
    ),
    JointConfig(
      id: 'J5',
      name: 'Wrist Rotation',
      channel: 'CH4',
      minAngle: 0,
      maxAngle: 180,
      defaultAngle: 0,
    ),
    JointConfig(
      id: 'J6',
      name: 'Gripper',
      channel: 'CH5',
      minAngle: 0,
      maxAngle: 90,
      defaultAngle: 0,
    ),
  ];
}
