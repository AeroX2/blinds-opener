$fn=30;

wall_screw_diameter = 5.5;
wall_screw_distance = 23.5;
wall_screw_tolerance = 5;

box_width = 32;
box_thickness = 25;
box_plus_gear = 62;
box_height = 46;

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

mount_thickness = 5;

module screw() {
    rotate([90,0,0]) {
        hull() {
            translate([0,0,10]) #cylinder(d=wall_screw_diameter, h=10);
            translate([0,wall_screw_tolerance,0]) cylinder(d=wall_screw_diameter, h=10);
        }
    }
}

module mounting_plate() {
    screw();
    translate([0,0,wall_screw_distance]) screw();
    // cube([10,10,10]);

}

module mounting_box() {
    minkowski() {
        translate([-mount_thickness, -mount_thickness, -mount_thickness])
        cube([
            box_width+mount_thickness*2,
            box_thickness+mount_thickness*2,
            box_height+mount_thickness*2
        ]);
        sphere(r=5);
    }
}

module motor_plate() {
    difference() {
        cube([box_width,10,box_height]);
        rotate([-90,0,0]) {
            translate([
                screw_offset_thickness,
                -screw_offset_height,
                0
            ]) cylinder(d=screw_hole_diameter,h=30);
            translate([
                screw_offset_thickness,
                -box_height+screw_offset_height,
                0
            ]) cylinder(d=screw_hole_diameter,h=30);
            translate([
                box_width-screw_offset_thickness,
                -screw_offset_height,
                0
            ]) cylinder(d=screw_hole_diameter,h=30);
            translate([
                box_width-screw_offset_thickness,
                -box_height+screw_offset_height,
                0
            ]) cylinder(d=screw_hole_diameter,h=30);

            // Center axle
            translate([
                box_width/2,
                -center_axle_offset,
                0
            ]) cylinder(d=center_axle_diameter,h=30);

            //Blob
            translate([
                box_width/2,
                -blob_offset,
                0
            ]) hull() {
                translate([+blob_width/2-blob_height/2,0,0]) cylinder(d=blob_height,h=30);
                translate([-blob_width/2+blob_height/2,0,0]) cylinder(d=blob_height,h=30);
            }
        }
    }
}

mounting_plate();
// mounting_box();
// motor_plate();