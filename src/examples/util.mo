import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import EIC "mo:base/ExperimentalInternetComputer";
import StableMemory "mo:base/ExperimentalStableMemory";

import Debug "mo:base/Debug";

module{ 
    public func factorial(d: Nat): Nat{
        var i : Nat = 1;
        var j : Nat = 1;
        var counter = 0;
        while(j <= d){
            i := i * j;
            j := j + 1;
        };
        return i;
    };
};