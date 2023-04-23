/* Changes

	Tobiasstrife

		DONE:

		Since Rev 106

		Built redesigned medical satelite for testing new pipe atmo control.
		Added filtered inlets and filtered/regulated vents.
			Added 5 associated filters.
			Gas specific turf_add procs.
			Filter specifc turf_take procs.
			Associated redesigned/new icons.
		Added functional pumps.
		Changed global FLOWFRAC from .05 to .99.
		Added "white" canister, aka: atmosphere reservoir.  Contains air mixture.
		Fixed typo somewhere in monkey mode win display

		TODO:

		Since Rev 106

		Remap SS13 atmo system!!
		Polish medical satelite.
		Rethink atmo reservoir
		Redesign some icons, especially for pump and reservoir
		Add new items to pipe adding/removing systems when Hobnob gets it done.


*/


/* Most recent changes (Since H9.6)

	Contining reorg of obj/machinery code
	Changed how solar panel directions are displayed, to fix the rotation display bug.

	Added remote APC control the power_monitor
	Fixed a bug where APCs would continue to draw power for cell charging even when the breaker was off.

	Added CO2 to gasbomb proc (plasmatank/proc/release())

	Moved computer objects ex_act() to base type (since all are identical)



	 (Since H9.5)

	Started pipelaying system, /obj/item/pipe.

	Added burning icon for labcoat
	Fixed a minor airsystem bug for /obj/moves
	Fixed admin toggle of mode-voting message (now reports state of allowvotemode correctly)
	Engine ejection now carries over firelevel of turfs
	Fixed bug with aux engine not working if started too quickly.

	Converted pipelines to use list exclusively, rather than numbers (so that list can be modified)
	Continues pipe laying - some checking of new lines now done, needs 2-pipe case

	Finished pipe laying - needs checking for all cases

	Updated autolathe to make pipe fittings

	Changed maximum circulator rates to give a better range of working values.
	Fixed firealarm triggering when unpowered.
	Made a temporary fix to runtime errors when blob attacks pipes (until full pipe damage system implemented).

	Code reorganization of obj/machinery continued.

*/



/*  To-do list

	Bugs:
	hearing inside closets/pods
	check head protection when hit by tank etc.


	gas progagation btwen obj/move & turfs - no flow
	due to turf/updatecell not counting /obj/moves as sources
	//firelevel lost when ejecting engine


	bug with two single-length pipes overlaying - pipeline ends up with no members

	alarm continuing when power out?



	New:

	recode obj/move stuff to use turfs exclusively?

	make regular glass melt in fire
	Blood splatters, can sample DNA & analyze
	also blood stains on clothing - attacker & defender

	whole body anaylzer in medbay - shows damage areas in popup?

	try station map maximizing use of image rather than icon

	useful world/Topic commands

	flow rate maximum for pipes - slowest of two connected notes

	system for breaking / making pipes, handle deletion, pipeline spliting/rejoining etc.


	add power-off mode for computers & other equipment (with reboot time)

	make grilles conductive for shocks (again)

	for prison warden/sec - baton allows precise targeting

	portable generator - hook to wire system

	modular repair/construction system
	maintainance key
	diagnostic tool
	modules - module construction


	hats/caps
	suit?

	build/unbuild engine floor with rf sheet

	crowbar opens airlocks when no power

*/




var/global/world_message = "Welcome to OpenSS13!"
var/global/savefile_ver = "4"
var/global/SS13_version = "1.1.3 - 10/14/2020"
var/global/changes = {"<FONT color='blue'><H3>Version: [SS13_version]</H3><B>Changes from base version 1</B></FONT><BR>
<HR>
<p><B>Doubled frames per second. Updated procs that were being phased out with their successors. Made 513 compatible by fixing reserved var/proc name errors. Made mobs capable of sight.
</B></p>
"}
var/global/datum/air_tunnel/air_tunnel1/SS13_airtunnel
var/global/datum/control/cellular/cellcontrol
var/global/datum/control/gameticker/ticker
var/global/obj/datacore/data_core
var/global/obj/overlay/plmaster
var/global/obj/overlay/liquidplmaster
var/global/obj/overlay/slmaster
var/global/going = 1.0
var/global/master_mode = "random"//"extended"

var/global/persistent_file = "mode.txt"

var/global/nuke_code
var/global/poll_controller
var/global/datum/engine_eject/engine_eject_control
var/global/host
var/global/obj/hud/main_hud
var/global/obj/hud/hud2/main_hud2
var/global/ooc_allowed = 1.0
var/global/dna_ident = 1.0
var/global/abandon_allowed = 1.0
var/global/enter_allowed = 1.0
var/global/shuttle_frozen = 0.0
var/global/prison_entered

var/global/list/html_colours = list()
var/global/list/occupations = list(
	"Engineer",
	"Engineer",
	"Security Officer",
	"Security Officer",
	"Forensic Technician",
	"Medical Researcher",
	"Research Technician",
	"Toxin Researcher",
	"Atmospheric Technician",
	"Medical Doctor",
	"Station Technician",
	"Head of Personnel",
	"Head of Research",
	"Prison Security",
	"Prison Security",
	"Prison Doctor",
	"Prison Warden",
	"AI",
)
var/global/list/assistant_occupations = list(
	"Technical Assistant",
	"Medical Assistant",
	"Research Assistant",
	"Staff Assistant",
)
var/global/list/bombers = list()
var/global/list/admins = list()
var/global/list/shuttles = list()
var/global/list/reg_dna = list()
var/global/list/banned = list()


var/global/shuttle_z = 10	//default
var/global/list/monkeystart = list()
var/global/list/blobstart = list()
var/global/list/blobs = list()
var/global/list/cardinal = list( NORTH, EAST, SOUTH, WEST )


var/global/datum/station_state/start_state
var/global/datum/config/config
var/global/datum/vote/vote
var/global/datum/sun/sun

var/global/list/plines = list()
var/global/list/gasflowlist = list()
var/global/list/machines = list()

var/global/list/powernets

var/global/defer_powernet_rebuild = 0		// true if net rebuild will be called manually after an event

var/global/Debug = 0	// global debug switch

var/global/datum/debug/debugobj

var/global/datum/moduletypes/mods = new()

var/global/wavesecret = 0

//airlockWireColorToIndex takes a number representing the wire color, e.g. the orange wire is always 1, the dark red wire is always 2, etc. It returns the index for whatever that wire does.
//airlockIndexToWireColor does the opposite thing - it takes the index for what the wire does, for example AIRLOCK_WIRE_IDSCAN is 1, AIRLOCK_WIRE_POWER1 is 2, etc. It returns the wire color number.
//airlockWireColorToFlag takes the wire color number and returns the flag for it (1, 2, 4, 8, 16, etc)
var/global/list/airlockWireColorToFlag = RandomAirlockWires()
var/global/list/airlockIndexToFlag
var/global/list/airlockIndexToWireColor
var/global/list/airlockWireColorToIndex
var/global/list/airlockFeatureNames = list("IdScan", "Main power In", "Main power Out", "Drop door bolts", "Backup power In", "Backup power Out", "Power assist", "AI Control", "Electrify")

var/global/numDronesInExistance = 0
