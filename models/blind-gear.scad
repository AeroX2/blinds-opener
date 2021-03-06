use <coupler.scad>;

$fn = 30;

// tolerance = 3;

ball_chain_width = 1;
ball_radius = 5/2;
ball_distance = 6.35;

gear_radius = 60/2;
gear_rim = 6;
gear_height = ball_radius*2 + 13;

// TODO(jridey) Should be based upon the ball_distance
ball_chain_amount = 26;

spoke_width = ball_chain_width;

module base() {
    difference() {
        cylinder(r=gear_radius, h=gear_height, center=true, $fn=100);
        rotate_extrude(convexity = 10)
        translate([gear_radius, 0, 0])
        circle(gear_height/2 + 3 - gear_rim);
    }
}

module ball_chain() {
    offset_radius = gear_radius - ball_radius*2.5;
    for (i=[1:ball_chain_amount])  {
        rotate(i*(360/ball_chain_amount))
        translate([
            offset_radius,
            0,
            0,
        ]) 
        union() {
            sphere(ball_radius);
            rotate([90,0,90]) translate([0,0,5]) cylinder(r=ball_radius, h=10, center=true);
        }
    }
}

module spokes() {
    rotate((360/ball_chain_amount) / 2)
    for (i=[1:ball_chain_amount])  {
        rotate(i*(360/ball_chain_amount))
        translate([gear_radius- ball_radius*2.5,0,0])
        rotate([90,0,0])
        union() {
            cylinder(r=1, h=2.5, center=true);
            // translate([2.3,0,0])
            // cube([5,2,3], center=true);
        }
    }
}

// module shaft() {
//     translate([0,0,-gear_height/2-1])
//     difference() {
//         cylinder(r=axle_radius, h=gear_height+2, $fs=50);
//         translate([axle_radius - 0.5,-5,1]) cube(size=[5, 10, gear_height+2]);
//     }
// }

difference() {
    base();
    ball_chain();
    spokes();
    translate([0,0,gear_height/2+0.01]) resize([21,21,0], auto=[true,true,false]) coupler(2.5);
}
translate([0,0,-gear_height/2-5])
cylinder(d=12, h=5);