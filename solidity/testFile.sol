// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract University {
    uint public studyYear;
    struct StudentData {
        uint256 age;
        string name;
    }
    StudentData[] public studentData;

    function setStudyYear (uint256 year) public {
        studyYear = year;
    }

    function getStudyYear () public view returns(string memory) {
        string memory last = "Congrats on getting into the university";
        if (studyYear == 3 || studyYear == 4) {
            string memory output1 = "You're almost a graudate, congrats in anticipation"; 
            return output1;
        }
        else if (studyYear >= 5) {
            string memory output2 = "We only offer 4 years courses, check again."; 
            return output2;
        }
        else if (studyYear <= 0) {
            string memory output3 = "Invalid year."; 
            return output3;
        } 
        return last;
    }

    function setStudentData(uint256 age, string calldata name) public {
        studentData.push(StudentData(age, name));
    }
    // function getStudentData() public view returns(StudentData calldata) {
    //     return studentData;
    // }
}