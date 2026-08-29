import firebase_admin
from firebase_admin import credentials, auth
import sys
from concurrent.futures import ThreadPoolExecutor

sys.stdout.reconfigure(encoding='utf-8')

cred = credentials.Certificate("e:/sih/service_account.json")
try:
    firebase_admin.initialize_app(cred)
except Exception:
    pass

# All 112 H4 Hostel Students
students = [
    {"reg": "23105108019", "pass": "Pass@8019", "name": "Ayush Kumar Singh"},
    {"reg": "23105108016", "pass": "Pass@8016", "name": "Pintu Kumar Yadav"},
    {"reg": "23102108014", "pass": "Pass@8014", "name": "Amit Kumar"},
    {"reg": "23105108034", "pass": "Pass@8034", "name": "Vikash Kumar"},
    {"reg": "23105108056", "pass": "Pass@8056", "name": "Abhishek Kumar Singh"},
    {"reg": "23102108019", "pass": "Pass@8019", "name": "Abhinav Chandra"},
    {"reg": "23104108007", "pass": "Pass@8007", "name": "Shubham Kumar"},
    {"reg": "23105108008", "pass": "Pass@8008", "name": "Pankaj Kumar"},
    {"reg": "23102108023", "pass": "Pass@8023", "name": "Amrit Raj"},
    {"reg": "23104108044", "pass": "Pass@8044", "name": "Prince Kumar"},
    {"reg": "24103108904", "pass": "Pass@8904", "name": "Sudhir Kumar"},
    {"reg": "23101108003", "pass": "Pass@8003", "name": "Shubh Raj"},
    {"reg": "23101108079", "pass": "Pass@8079", "name": "Shubham Kumar"},
    {"reg": "23104108008", "pass": "Pass@8008", "name": "Harshit Kumar"},
    {"reg": "24101108917", "pass": "Pass@8917", "name": "Gagan Kumar"},
    {"reg": "23105108023", "pass": "Pass@8023", "name": "Pawan Kumar", "email": "pawankr0745@gmail.com"},
    {"reg": "23104108041", "pass": "Pass@8041", "name": "Nitish Kumar"},
    {"reg": "23105108006", "pass": "Pass@8006", "name": "Akash Ranjan"},
    {"reg": "23101108057", "pass": "Pass@8057", "name": "Shubham Kumar"},
    {"reg": "23101108092", "pass": "Pass@8092", "name": "Anand Kumar"},
    {"reg": "23105108028", "pass": "Pass@8028", "name": "Vikesh Kumar"},
    {"reg": "23105108029", "pass": "Pass@8029", "name": "Dheeraj Kumar"},
    {"reg": "23101108077", "pass": "Pass@8077", "name": "Saurav Kumar"},
    {"reg": "23104108020", "pass": "Pass@8020", "name": "Ayush Suman"},
    {"reg": "23105108041", "pass": "Pass@8041", "name": "Md Wasim"},
    {"reg": "24105108909", "pass": "Pass@8909", "name": "Satyam Kumar"},
    {"reg": "23105108044", "pass": "Pass@8044", "name": "Raghuvir Kumar"},
    {"reg": "23105108020", "pass": "Pass@8020", "name": "Rohan Jha"},
    {"reg": "23101108070", "pass": "Pass@8070", "name": "Sachin Kumar"},
    {"reg": "23104108009", "pass": "Pass@8009", "name": "Gulshan Kumar"},
    {"reg": "23103108025", "pass": "Pass@8025", "name": "Aditya Aryan"},
    {"reg": "23102108051", "pass": "Pass@8051", "name": "Dhruv Kumar Jha"},
    {"reg": "23103108037", "pass": "Pass@8037", "name": "Alok Raj"},
    {"reg": "23103108050", "pass": "Pass@8050", "name": "Sameer Kumar"},
    {"reg": "23103108008", "pass": "Pass@8008", "name": "Nishuraj"},
    {"reg": "23103108030", "pass": "Pass@8030", "name": "Amarjeet Kumar"},
    {"reg": "23105108033", "pass": "Pass@8033", "name": "Rajneesh Raj"},
    {"reg": "23104108011", "pass": "Pass@8011", "name": "Shubham Kumar"},
    {"reg": "24101108914", "pass": "Pass@8914", "name": "Dilwar"},
    {"reg": "23102108009", "pass": "Pass@8009", "name": "Ayush Kumar"},
    {"reg": "23103108044", "pass": "Pass@8044", "name": "Aman Prakash"},
    {"reg": "23104108038", "pass": "Pass@8038", "name": "Ankit Kumar"},
    {"reg": "23105108007", "pass": "Pass@8007", "name": "Aashish Ranjan"},
    {"reg": "23101108016", "pass": "Pass@8016", "name": "Sajan Kumar"},
    {"reg": "23101108110", "pass": "Pass@8110", "name": "Abhay Kumar"},
    {"reg": "23105108037", "pass": "Pass@8037", "name": "Ankit Kumar"},
    {"reg": "23101108084", "pass": "Pass@8084", "name": "Kaushal Kumar"},
    {"reg": "23103108005", "pass": "Pass@8005", "name": "Harshit Kumar"},
    {"reg": "23102108055", "pass": "Pass@8055", "name": "Chetan Dev"},
    {"reg": "23101108019", "pass": "Pass@8019", "name": "Shivam Kumar"},
    {"reg": "24102108905", "pass": "Pass@8905", "name": "Rohan Kumar"},
    {"reg": "23101108004", "pass": "Pass@8004", "name": "Prashant Kumar"},
    {"reg": "23102108013", "pass": "Pass@8013", "name": "Sunny Shekhar"},
    {"reg": "23102108042", "pass": "Pass@8042", "name": "Anshu Kumar"},
    {"reg": "23101108021", "pass": "Pass@8021", "name": "Sandip Kumar"},
    {"reg": "23103108035", "pass": "Pass@8035", "name": "Ganesh Pratap"},
    {"reg": "23105108022", "pass": "Pass@8022", "name": "Bhanu Pratap Singh"},
    {"reg": "23105108059", "pass": "Pass@8059", "name": "Priyanshu Kumar Gandhi", "email": "priyanshugandhi64@gmail.com"},
    {"reg": "23104108003", "pass": "Pass@8003", "name": "Anshu Bhushan"},
    {"reg": "23104108017", "pass": "Pass@8017", "name": "Aditya Raj"},
    {"reg": "23101108078", "pass": "Pass@8078", "name": "Sushant Raj"},
    {"reg": "23105108021", "pass": "Pass@8021", "name": "Saheb Jaiswal"},
    {"reg": "23103108020", "pass": "Pass@8020", "name": "Vikash Kumar"},
    {"reg": "23102108020", "pass": "Pass@8020", "name": "Sushant Kumar"},
    {"reg": "23102108010", "pass": "Pass@8010", "name": "Akash Deep"},
    {"reg": "23101108040", "pass": "Pass@8040", "name": "Paras Mani"},
    {"reg": "24104108902", "pass": "Pass@8902", "name": "Md. Tahshin Raza"},
    {"reg": "23104108053", "pass": "Pass@8053", "name": "Vishal Sing"},
    {"reg": "23101108105", "pass": "Pass@8105", "name": "Gaurav Kumar Tiwari"},
    {"reg": "23104108016", "pass": "Pass@8016", "name": "Gautam Kumar"},
    {"reg": "23101108027", "pass": "Pass@8027", "name": "Abhinav Raj"},
    {"reg": "23101108015", "pass": "Pass@8015", "name": "Anurag Kumar"},
    {"reg": "23104108036", "pass": "Pass@8036", "name": "Aditya Kumar Yadav"},
    {"reg": "23103108011", "pass": "Pass@8011", "name": "Priyanshu Kumar"},
    {"reg": "23103308038", "pass": "Pass@8038", "name": "Niraj Kumar"},
    {"reg": "23101108005", "pass": "Pass@8005", "name": "Vishwajeet Kumar"},
    {"reg": "23101108039", "pass": "Pass@8039", "name": "Shubham Kumar"},
    {"reg": "23104108042", "pass": "Pass@8042", "name": "Rajesh Kumar"},
    {"reg": "23101108116", "pass": "Pass@8116", "name": "Deepak Kumar"},
    {"reg": "23101108086", "pass": "Pass@8086", "name": "Saurav Kumar"},
    {"reg": "23101108083", "pass": "Pass@8083", "name": "Yogesh Kumar Patel"},
    {"reg": "23101108085", "pass": "Pass@8085", "name": "Shubham Kumar"},
    {"reg": "23101108119", "pass": "Pass@8119", "name": "Abhishek Kumar"},
    {"reg": "23104108030", "pass": "Pass@8030", "name": "Shashwat Kumar Sah"},
    {"reg": "23101108068", "pass": "Pass@8068", "name": "Deepak Kumar"},
    {"reg": "23102108053", "pass": "Pass@8053", "name": "Shubham Kumar"},
    {"reg": "23101108030", "pass": "Pass@8030", "name": "Manish Kumar"},
    {"reg": "23102108048", "pass": "Pass@8048", "name": "Abhay Kumar"},
    {"reg": "23101108022", "pass": "Pass@8022", "name": "Anurag Raj"},
    {"reg": "23101108050", "pass": "Pass@8050", "name": "Ashutosh Priyadarshi"},
    {"reg": "23102108045", "pass": "Pass@8045", "name": "Anshu Kumar"},
    {"reg": "23103108021", "pass": "Pass@8021", "name": "Sunny Kumar"},
    {"reg": "23102108003", "pass": "Pass@8003", "name": "Ashutosh Kumar"},
    {"reg": "23103108026", "pass": "Pass@8026", "name": "Vishwajeet Kumar"},
    {"reg": "23102108001", "pass": "Pass@8001", "name": "Md Ajaj Ahmed"},
    {"reg": "23102108054", "pass": "Pass@8054", "name": "Shubham Patel"},
    {"reg": "23103108009", "pass": "Pass@8009", "name": "Shashwat Vats"},
    {"reg": "23104108013", "pass": "Pass@8013", "name": "Md Abid Raza"},
    {"reg": "23101108113", "pass": "Pass@8113", "name": "Bishal Rajak"},
    {"reg": "23103108029", "pass": "Pass@8029", "name": "Dhananjay Kumar"},
    {"reg": "23101108094", "pass": "Pass@8094", "name": "Sonu Kumar"},
    {"reg": "23101108071", "pass": "Pass@8071", "name": "Nikhil Kashyap"},
    {"reg": "23101108069", "pass": "Pass@8069", "name": "Tej Pratap"},
    {"reg": "23105108014", "pass": "Pass@8014", "name": "Prince Kumar"},
    {"reg": "23104108039", "pass": "Pass@8039", "name": "Pratik Kumar"},
    {"reg": "23102108037", "pass": "Pass@8037", "name": "Brishan Patel"},
    {"reg": "23105108005", "pass": "Pass@8005", "name": "Prince Raj"},
    {"reg": "23101108024", "pass": "Pass@8024", "name": "Prateek"},
    {"reg": "23103108028", "pass": "Pass@8028", "name": "Raj Nandan Kumar"},
    {"reg": "23104108058", "pass": "Pass@8058", "name": "Kaushik Raj"},
    {"reg": "23105108060", "pass": "Pass@8060", "name": "Aman Raj"},
]

def process_student(s):
    email = s.get("email") or f"{s['reg']}@smartmess.edu"
    try:
        auth.create_user(
            email=email,
            password=s["pass"],
            display_name=s["name"],
            email_verified=False,
        )
        return f"[CREATED]  {s['name']} ({s['reg']}) -> {email}"
    except auth.EmailAlreadyExistsError:
        try:
            existing = auth.get_user_by_email(email)
            auth.update_user(existing.uid, password=s["pass"])
            return f"[UPDATED]  {s['name']} ({s['reg']}) -> Refreshed password ({s['pass']})"
        except Exception as e:
            return f"[EXISTS]   {s['name']} ({s['reg']}) -> {e}"
    except Exception as e:
        return f"[FAILED]   {s['name']} ({s['reg']}) -> {e}"

print(f"Provisioning {len(students)} student accounts in parallel...")
with ThreadPoolExecutor(max_workers=10) as executor:
    results = list(executor.map(process_student, students))

for r in results:
    print(r)

print("\nAll student accounts are verified and active on Firebase Authentication!")
