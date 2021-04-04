$fn=20;

wall_screw_diameter = 4.5;
wall_screw_outer_diameter = 7;
wall_screw_head_height = 3; 
wall_screw_distance = 23.5;
wall_screw_offset = 10;
wall_screw_tolerance = 10;

gearbox_depth = 31;
gearbox_thickness = 24;
gearbox_height_without_motor = 46;
gearbox_motor_height = 39;

gearbox_axle_diameter = 15 + 7; // +7 to account for axle being offset
gearbox_axle_thickness = 12 + 2; // +2 for tolerance
gearbox_axle_offset = 15;

gearbox_gear_diameter = 67;
gearbox_gear_thickness = 18 + 2; // +2 for tolerance

gearbox_full_thickness = gearbox_thickness + gearbox_axle_thickness + gearbox_gear_thickness;
gearbox_full_height = gearbox_height_without_motor + gearbox_motor_height;

mount_width = 32;
mount_thickness = 5;

axle_to_top_screw = 33;
screw_bottom_offset = 17;

box_height = 40;
box_offset = screw_bottom_offset + wall_screw_distance + axle_to_top_screw;
box_thickness = 5;

cuo = 200;
ep = 0.01;
ep2 = ep*2;

module capsule(height, width, length, width2 = "undefined") {
    rotate([-90,0,0]) {
        hull() {
            translate([-ep,-height/2,0]) if (width2 == "undefined") {
                cylinder(d=width, h=length);
            } else {
                cylinder(d1=width, d2=width2, h=length);
            }
            translate([-ep,height/2,0]) if (width2 == "undefined") {
                cylinder(d=width, h=length);
            } else {
                cylinder(d1=width, d2=width2, h=length);
            }
        }
    }
}

module motor_profile() {
    translate([
        gearbox_depth/2 + ep,
        0,
        gearbox_full_height - gearbox_axle_offset,
    ]) 
    rotate([90,0,0])
    cylinder(d=13, h=20);

    translate([
        gearbox_depth/2 - 13/2,
        -mount_thickness - ep2,
        -10,
    ]) 
    cube([100,mount_thickness+ep,gearbox_full_height - gearbox_axle_offset + 10]);

    translate([
        gearbox_depth/2,
        0,
        gearbox_full_height - gearbox_axle_offset - cuo/2,
    ])
    capsule(cuo, gearbox_gear_diameter, gearbox_gear_thickness);

    translate([
        gearbox_depth/2,
        gearbox_gear_thickness - ep,
        gearbox_full_height - gearbox_axle_offset - cuo/2,
    ])
    capsule(cuo, gearbox_axle_diameter, gearbox_axle_thickness+ep2);

    translate([
        0,
        gearbox_gear_thickness + gearbox_axle_thickness - ep,
        gearbox_full_height - cuo,
    ])
    cube([gearbox_depth, gearbox_thickness+ep2, cuo]);
}

module screw() {
    capsule(wall_screw_tolerance, wall_screw_diameter, 100);
    capsule(wall_screw_tolerance, wall_screw_outer_diameter, wall_screw_head_height, wall_screw_diameter);
}

module mounting_plate() {
    difference() {
        union() {
            translate([-mount_width, 0, 0])
            cube([mount_width+35, mount_thickness, box_offset + box_height]);

            translate([-5, 0, box_offset + box_height - 20])
            cube([gearbox_depth + mount_thickness + 4, gearbox_gear_thickness+box_thickness+mount_thickness, 20]);

            translate([-mount_thickness, mount_thickness+gearbox_gear_thickness, box_offset - 25])
            cube([mount_width+mount_thickness*2, gearbox_axle_thickness+gearbox_thickness+mount_thickness, box_height + 25]);
        }

        translate([-20, mount_thickness+ep, screw_bottom_offset]) rotate([0,0,180]) {
            screw();
            translate([0, 0, wall_screw_distance]) screw();
        }
    }
}

difference() {
    mounting_plate();
    translate([mount_width/2 - gearbox_depth/2, mount_thickness + ep, box_offset-gearbox_full_height+gearbox_axle_offset]) motor_profile(); 
}
