module RubyFit::MessageConstants
  COURSE_POINT_TYPE = {
    invalid: 255,
    generic: 0,
    summit: 1,
    valley: 2,
    water: 3,
    food: 4,
    danger: 5,
    left: 6,
    right: 7,
    straight: 8,
    first_aid: 9,
    fourth_category: 10,
    third_category: 11,
    second_category: 12,
    first_category: 13,
    hors_category: 14,
    sprint: 15,
    left_fork: 16,
    right_fork: 17,
    middle_fork: 18,
    slight_left: 19,
    sharp_left: 20,
    slight_right: 21,
    sharp_right: 22,
    u_turn: 23,
    segment_start: 24,
    segment_end: 25,
    campsite: 27,
    aid_station: 28,
    rest_area: 29,
    general_distance: 30, # Used with UpAhead
    service: 31,
    energy_gel: 32,
    sports_drink: 33,
    mile_marker: 34,
    checkpoint: 35,
    shelter: 36,
    meeting_spot: 37,
    overlook: 38,
    toilet: 39,
    shower: 40,
    gear: 41,
    sharp_curve: 42,
    steep_incline: 43,
    tunnel: 44,
    bridge: 45,
    obstacle: 46,
    crossing: 47,
    store: 48,
    transition: 49,
    navaid: 50,
    transport: 51,
    alert: 52,
    info: 53
  }.freeze

  EVENT_TYPE = {
    start: 0,
    stop: 1,
    consecutive_depreciated: 2,
    marker: 3,
    stop_all: 4,
    begin_depreciated: 5,
    end_depreciated: 6,
    end_all_depreciated: 7,
    stop_disable: 8,
    stop_disable_all: 9,
  }.freeze

  EVENT = {
    timer: 0, # Group 0.  Start / stop_all
    workout: 3, # start / stop
    workout_step: 4, # Start at beginning of workout.  Stop at end of each step.
    power_down: 5, # stop_all group 0
    power_up: 6, # stop_all group 0
    off_course: 7, # start / stop group 0
    session: 8, # Stop at end of each session.
    lap: 9, # Stop at end of each lap.
    course_point: 10, # marker
    battery: 11, # marker
    virtual_partner_pace: 12, # Group 1. Start at beginning of activity if VP enabled, when VP pace is changed during activity or VP enabled mid activity.  stop_disable when VP disabled.
    hr_high_alert: 13, # Group 0.  Start / stop when in alert condition.
    hr_low_alert: 14, # Group 0.  Start / stop when in alert condition.
    speed_high_alert: 15, # Group 0.  Start / stop when in alert condition.
    speed_low_alert: 16, # Group 0.  Start / stop when in alert condition.
    cad_high_alert: 17, # Group 0.  Start / stop when in alert condition.
    cad_low_alert: 18, # Group 0.  Start / stop when in alert condition.
    power_high_alert: 19, # Group 0.  Start / stop when in alert condition.
    power_low_alert: 20, # Group 0.  Start / stop when in alert condition.
    recovery_hr: 21, # marker
    battery_low: 22, # marker
    time_duration_alert: 23, # Group 1.  Start if enabled mid activity (not required at start of activity). Stop when duration is reached.  stop_disable if disabled.
    distance_duration_alert: 24, # Group 1.  Start if enabled mid activity (not required at start of activity). Stop when duration is reached.  stop_disable if disabled.
    calorie_duration_alert: 25, # Group 1.  Start if enabled mid activity (not required at start of activity). Stop when duration is reached.  stop_disable if disabled.
    activity: 26, # Group 1..  Stop at end of activity.
    fitness_equipment: 27, # marker
    length: 28, # Stop at end of each length.
    user_marker: 32, # marker
    sport_point: 33, # marker
    calibration: 36, # start/stop/marker
    front_gear_change: 42, # marker
    rear_gear_change: 43, # marker
    rider_position_change: 44, # marker
    elev_high_alert: 45, # Group 0.  Start / stop when in alert condition.
    elev_low_alert: 46, # Group 0.  Start / stop when in alert condition.
    comm_timeout: 47, # marker
  }.freeze

  ACTIVITY_TYPE = {
    generic: 0,
    running: 1,
    cycling: 2,
    transition: 3,
    fitness_equipment: 4,
    swimming: 5,
    walking: 6,
    sedentary: 8,
    all: 254
  }.freeze

  SPORT = {
    generic: 0,
    all: 254,

    # sports
    running: 1,
    cycling: 2,
    transition: 3,
    fitness_equipment: 4,
    swimming: 5,
    basketball: 6,
    soccer: 7,
    tennis: 8,
    american_football: 9,
    training: 10,
    walking: 11,
    cross_country_skiing: 12,
    alpine_skiing: 13,
    snowboarding: 14,
    rowing: 15,
    mountaineering: 16,
    hiking: 17,
    multisport: 18,
    paddling: 19,
    flying: 20,
    e_biking: 21,
    motorcycling: 22,
    boating: 23,
    driving: 24,
    golf: 25,
    hang_gliding: 26,
    horseback_riding: 27,
    hunting: 28,
    fishing: 29,
    inline_skating: 30,
    rock_climbing: 31,
    sailing: 32,
    ice_skating: 33,
    sky_diving: 34,
    snowshoeing: 35,
    snowmobiling: 36,
    stand_up_paddleboarding: 37,
    surfing: 38,
    wakeboarding: 39,
    water_skiing: 40,
    kayaking: 41,
    rafting: 42,
    windsurfing: 43,
    kitesurfing: 44,
    tactical: 45,
    jumpmaster: 46,
    boxing: 47,
    floor_climbing: 48,
    baseball: 49,
    diving: 53,
    hiit: 62,
    racket: 64,
    wheelchair_push_walk: 65,
    wheelchair_push_run: 66,
    meditation: 67,
    disc_golf: 69,
    cricket: 71,
    rugby: 72,
    hockey: 73,
    lacrosse: 74,
    volleyball: 75,
    water_tubing: 76,
    wakesurfing: 77,
    mixed_martial_arts: 80,
    snorkeling: 82,
    dance: 83,
    jump_rope: 84
  }.freeze

  SUB_SPORT = {
    generic: 0,

    # sub-sports
    treadmill: 1,
    street: 2,
    trail: 3,
    track: 4,
    spin: 5,
    indoor_cycling: 6,
    road: 7,
    mountain: 8,
    downhill: 9,
    recumbent: 10,
    cyclocross: 11,
    hand_cycling: 12,
    track_cycling: 13,
    indoor_rowing: 14,
    elliptical: 15,
    stair_climbing: 16,
    lap_swimming: 17,
    open_water: 18,
    flexibility_training: 19,
    strength_training: 20,
    warm_up: 21,
    match: 22,
    exercise: 23,
    challenge: 24,
    indoor_skiing: 25,
    cardio_training: 26,
    indoor_walking: 27,
    e_bike_fitness: 28,
    bmx: 29,
    casual_walking: 30,
    speed_walking: 31,
    bike_to_run_transition: 32,
    run_to_bike_transition: 33,
    swim_to_bike_transition: 34,
    atv: 35,
    motocross: 36,
    backcountry: 37,
    resort: 38,
    rc_drone: 39,
    wingsuit: 40,
    whitewater: 41,
    skate_skiing: 42,
    yoga: 43,
    pilates: 44,
    indoor_running: 45,
    gravel_cycling: 46,
    e_bike_mountain: 47,
    commuting: 48,
    mixed_surface: 49,
    navigate: 50,
    track_me: 51,
    map: 52,
    single_gas_diving: 53,
    multi_gas_diving: 54,
    gauge_diving: 55,
    apnea_diving: 56,
    apnea_hunting: 57,
    virtual_activity: 58,
    obstacle: 59,
    breathing: 62,
    sail_race: 65,
    ultra: 67,
    indoor_climbing: 68,
    bouldering: 69,
    hiit_sub_sport: 70,
    amrap: 73,
    emom: 74,
    tabata: 75,
    pickleball: 84,
    padel: 85,
    indoor_wheelchair_walk: 86,
    indoor_wheelchair_run: 87,
    indoor_hand_cycling: 88,
    squash: 94,
    badminton: 95,
    racquetball: 96,
    table_tennis: 97,
    fly_canopy: 110,
    fly_paraglide: 111,
    fly_paramotor: 112,
    fly_pressurized: 113,
    fly_navigate: 114,
    fly_timer: 115,
    fly_altimeter: 116,
    fly_wx: 117,
    fly_vfr: 118,
    fly_ifr: 119
  }.freeze

  SESSION_TRIGGER = {
    activity_end: 0,
    manual: 1,
    auto_multi_sport: 2,
    fitness_equipment: 3
  }

  SWIM_STROKE = {
    freestyle: 0,
    backstroke: 1,
    breastroke: 2,
    butterfly: 3,
    drill: 4,
    mixed: 5,
    im: 6
  }

  DISPLAY_MEASURE = {
    metric: 0,
    statute: 1,
    nautical: 2
  }
end
