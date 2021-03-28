$fn=50;

wall_screw_diameter = 5.5;
wall_screw_distance = 23.5;
wall_screw_offset = 10;
wall_screw_tolerance = 5;

box_width = 32;
box_thickness = 24;
box_plus_gear = 60;
box_gear_width = 36;

box_height = 46;
box_full_height = 84;
box_motor_height = box_full_height - box_height;
box_motor_diameter = 24;

screw_hole_diameter = 7.5;
screw_offset_height = 6;
screw_offset_thickness = 7;
screw_length = 33;
screw_width = 18;

center_axle_diameter = 13;
center_axle_offset = 15;

blob_width = 16;
blob_height = 6;
blob_offset = 31.5 - blob_height/2;

mount_width = box_width;
mount_thickness = 5;

ep = 0.001;
ep2 = ep*2;

module motor_profile() {
    translate([0,0,box_motor_height])
    cube([box_width, box_thickness, box_height]);

    translate([box_width-box_motor_diameter/2,box_motor_diameter/2+3,ep])
    cylinder(d=box_motor_diameter,h=100);

    translate([box_width-3,box_motor_diameter-3,50])
    rotate([0,0,-60])
    cube([15,8,100], center=true);
}

module screw() {
    rotate([-90,0,0]) {
        hull() {
            translate([-ep,-wall_screw_tolerance/2,0]) cylinder(d=wall_screw_diameter, h=200);
            translate([-ep,wall_screw_tolerance/2,0]) cylinder(d=wall_screw_diameter, h=200);
        }

        hull() {
            translate([-ep,-wall_screw_tolerance/2,mount_thickness*1.5+ep]) cylinder(d1=wall_screw_diameter, d2=wall_screw_diameter*2, h=mount_thickness/2);
            translate([-ep,wall_screw_tolerance/2,mount_thickness*1.5+ep]) cylinder(d1=wall_screw_diameter, d2=wall_screw_diameter*2, h=mount_thickness/2);
        }
    }
}

module mounting_plate() {
    difference() {
        translate([-mount_thickness/2, 0, -mount_thickness*2-ep])
        cube([box_width+mount_thickness+3, box_plus_gear+mount_thickness+2, box_full_height+mount_thickness*2]);

        translate([box_width/2, mount_thickness+ep, box_full_height-center_axle_offset])
        rotate([-90, 0, 0])
        cylinder(d=75, h=22);

        translate([box_width/2+1, mount_thickness+ep, 0])
        hull() {
            translate([0, 0, box_full_height])
            rotate([-90, 0, 0])
            cylinder(d=20, h=50);

            translate([0, 0, box_full_height-center_axle_offset-5])
            rotate([-90, 0, 0])
            cylinder(d=20, h=50);
        }
    }
}


difference() {
    difference() {
        difference() {
            mounting_plate();
            translate([0, box_gear_width, 0])
            motor_profile();
        }
        translate([mount_width/2, -mount_thickness-ep, box_full_height-wall_screw_offset]) screw();
        translate([mount_width/2, -mount_thickness-ep, box_full_height-wall_screw_offset-wall_screw_distance]) screw();
        translate([mount_width/2, mount_thickness-ep, box_full_height-wall_screw_offset]) scale(1.4) screw();
        translate([mount_width/2, mount_thickness-ep, box_full_height-wall_screw_offset-wall_screw_distance]) scale(1.4) screw();
    }
    //Lazy method
    translate([-mount_thickness/2-ep, -mount_thickness/2-ep, -mount_thickness*2-ep2])
    cube([100,100,40]);
}

// mounting_box();
// motor_plate();