# Maame: plan for Full Self-Flying (FSF)

Nyansa Labs' goal for the Maame series is **Full Self-Flying**: an aircraft you give a goal, not a joystick. This page is the ground-station side of that plan: what MaameDrone-ArduDeck has to do at each level, and which open-source projects we intend to build on.

The aircraft side (companion computer, flight controller parameters, SITL tests) lives in the private Maame aircraft repo (`maame-air`, `docs/fsf-roadmap.md`). Candidate algorithms come from the community list [alexkoven/Autonomous-UAVs](https://github.com/alexkoven/Autonomous-UAVs).

## Levels

| Level | Name | What the aircraft does | Status |
|---|---|---|---|
| L0 | Remote cockpit | A person flies through the ground station: no RC, position hold only | Done |
| L1 | Mission autonomy | Flies planned missions, gates its own launch, handles failsafes, signed link | Done (first flight 16 Nov 2026) |
| **L2** | **Smart Flight** | The companion computer flies whole tasks: go-to and return, orbit, survey, search, patrol, payload drop, follow-me, plus a forward-lidar brake | **In simulation** |
| L3 | Perception | Camera + AI accelerator: precision landing, object detection, visual obstacle avoidance, flight without GPS | Needs the compute upgrade |
| L4 | Beyond line of sight | Supervised missions over 4G, remote take-over, landing at alternate sites | 4G modem arriving |
| L5 | Full Self-Flying | Goal-level commands ("inspect this mast"); plans, adapts and lands with no supervision | Research goal |

Every level must pass SITL and then a low, fenced field test before the next one starts.

## What ArduDeck does at each level

### L0 and L1 (done)

The Maame cockpit, coordinate missions, the pre-flight gate (ready checks, safety baseline, wind and vibration checks), hover and motor tests, and the emergency bar. All commands are MAVLink 2 signed.

### L2 Smart Flight (next for the ground station)

The aircraft already accepts Smart Flight tasks from the phone dashboard. ArduDeck needs the same:

- **Smart Flight card** in the Maame view: pick a task, click the map for the point, set height and size, start. It sends `COMMAND_INT` 31012 (`MAV_CMD_USER_3`) to the companion computer (component 191). The parameters follow the task table in the aircraft roadmap.
- **Pre-check before sending:** show the planned track on the map, its distance from home against the fence, and the estimated flight time against the battery reserve. These are the same checks the Pi runs, so a refusal is never a surprise.
- **Live status:** read `FSF_TASK` and `FSF_PROG` (`NAMED_VALUE_FLOAT`) and the companion's `STATUSTEXT`; show the task, its progress and why it ended (finished, obstacle brake, battery RTL, handed back).
- **Stop always wins:** a Stop button sends task 0, so the aircraft holds position in GUIDED. Any mode change from the cockpit or emergency bar hands control back as it does today.
- **Lidar view:** show the forward `DISTANCE_SENSOR` reading and the brake distance once the TF-Luna is fitted.

### L3 Perception

- Camera feed with detection overlays (boxes and labels sent from the companion).
- Precision-landing state: target seen, offset, landing or aborting.
- Visual-odometry health when GPS is weak: which source the EKF is using, and a clear warning when it falls back.

### L4 Beyond line of sight

- Telemetry and commands over 4G alongside SiK and Wi-Fi, with link quality per path in the link badge.
- Remote take-over that works over the slowest link, and alternate landing sites on the map.
- A flight log that records which operator and which link issued each command.

### L5 Full Self-Flying

- Goal entry ("inspect this mast", "deliver to this pin") instead of tasks, with the aircraft's plan shown back for approval.
- Explanations: why the aircraft chose a route, and what it is uncertain about.

## Building blocks from the Autonomous-UAVs list

Picked for what Maame can actually run: a Raspberry Pi companion now, Pi 5 + AI HAT+ planned for L3, ArduPilot on the flight controller. Most entries in the list are ROS-based research code; we take the ideas or the libraries, not whole stacks.

| Level | Need | Candidates from the list | Where it runs |
|---|---|---|---|
| L2 | Smooth tracks for orbit and survey instead of straight legs | [mav_trajectory_generation](https://github.com/ethz-asl/mav_trajectory_generation), [waypoint_navigator](https://github.com/ethz-asl/waypoint_navigator) | Companion |
| L2 | Task logic that stays readable as tasks grow | [ROS-Behavior-Tree](https://github.com/miccol/ROS-Behavior-Tree), [SMACH hierarchical state machines](http://wiki.ros.org/smach/Tutorials) | Companion |
| L2 | Reference algorithms to prototype in Python | [PythonRobotics](https://github.com/AtsushiSakai/PythonRobotics) | Desk, then companion |
| L3 | Flight without GPS | [VINS-Fusion](https://github.com/HKUST-Aerial-Robotics/VINS-Fusion), [OpenVINS](https://github.com/rpng/open_vins), [VINS-Mono](https://github.com/HKUST-Aerial-Robotics/VINS-Mono), [LARVIO](https://github.com/PetWorm/LARVIO) (monocular, light) | Companion |
| L3 | Landing on a marker | [tagSLAM](https://github.com/berndpfrommer/tagslam) (AprilTags) | Companion |
| L3 | A map of what is around the aircraft | [voxblox](https://github.com/ethz-asl/voxblox), [nanomap](https://github.com/peteflorence/nanomap_ros) | Companion |
| L3 | Learned obstacle avoidance on small hardware | [pulp-dronet](https://github.com/pulp-platform/pulp-dronet), [dronet](https://github.com/uzh-rpg/rpg_public_dronet) | Companion (AI HAT+) |
| L4 | Route planning around obstacles | [Fast-Planner](https://github.com/HKUST-Aerial-Robotics/Fast-Planner), [mav_voxblox_planning](https://github.com/ethz-asl/mav_voxblox_planning) | Companion |
| L5 | Task planning from a goal | [ROSPlan](https://github.com/KCL-Planning/ROSPlan) | Companion |
| L5 | Exploring unknown places | [aeplanner](https://github.com/mseln/aeplanner), [nbvplanner](https://github.com/ethz-asl/nbvplanner) | Companion |
| L5 | Several aircraft at once | [ego-planner-swarm](https://github.com/ZJU-FAST-Lab/ego-planner-swarm), [Robofleet](https://github.com/ut-amrl/robofleet) (multi-robot web control) | Companion + ground station |
| All | Testing in simulation beyond SITL | [Flightmare](https://github.com/uzh-rpg/flightmare) | Desk |
| All | Designing for failure | [resilience-engineering](https://github.com/lorin/resilience-engineering) | Process |

Low-level control stays with ArduPilot. The model-predictive and learned controllers in the list's Controls section are research references, not something we plan to replace ArduPilot with.

## Rules that do not change

- Every command is signed; the aircraft ignores unsigned stations.
- A human mode change always takes control back, at every level.
- Nothing flies in the field before it passes in SITL.
