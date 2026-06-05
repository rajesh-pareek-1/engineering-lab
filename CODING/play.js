const user = {
  name: "Rajesh",
  age: 23,
  profile: {
    role: "Software Engineer",
    ctc: "x-10",
  },
};

console.log(user);

const copiedUser = structuredClone(user);

copiedUser.name = "Archana";
copiedUser.profile.role = "QA";

console.log("original user : ", user);
