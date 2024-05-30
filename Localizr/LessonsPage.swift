import SwiftUI

struct LessonsPage: View {
    @State private var isButtonFilled: Bool = true // Control whether the buttons are filled or not

    var body: some View {
        VStack {
            Text("Lectures")
                .font(.largeTitle)
                .padding(.top, 10)
            VStack(spacing: 20) {
                Text("Live now")
                    .font(.title)
                    .padding(.top, 10)
                
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        LiveCardView(title: "Linear Algebra", room: "G3", isButtonFilled: isButtonFilled)
                        LiveCardView(title: "Signal, Networks and Learning", room: "G26.5", isButtonFilled: isButtonFilled)
                    }
                    HStack(spacing: 20) {
                        LiveCardView(title: "Electronics", room: "G60", isButtonFilled: isButtonFilled)
                        LiveCardView(title: "Informatics", room: "G42", isButtonFilled: isButtonFilled)
                    }
                }
                .cornerRadius(10)
                
                Text("Starting soon")
                    .font(.title)
                    .padding(.top, 20)
                
                VStack(spacing: 20) {
                    SoonCardView(title: "Statistical Learning", room: "G3", isButtonFilled: isButtonFilled)
                    SoonCardView(title: "Differential Geometry", room: "G5", isButtonFilled: isButtonFilled)
                }
                
                Spacer()
            }
            .padding()
            .cornerRadius(20)
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct LiveCardView: View {
    var title: String
    var room: String
    var isButtonFilled: Bool
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            Text(room)
                .font(.subheadline)
                .foregroundColor(.gray)
            NavigationLink(destination: NavigationMode(room: room)) {
                Text("Go To")
                    .foregroundColor(isButtonFilled ? .white : .red)
                    .padding()
                    .frame(width: 100, height: 40)
                    .background(isButtonFilled ? Color.red : Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(10)
    }
}

struct SoonCardView: View {
    var title: String
    var room: String
    var isButtonFilled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(room)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            NavigationLink(destination: NavigationMode(room: room)) {
                Text("Go To")
                    .foregroundColor(isButtonFilled ? .white : .blue)
                    .padding()
                    .frame(width: 100, height: 40)
                    .background(isButtonFilled ? Color.blue : Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
}

struct LessonsView_Previews: PreviewProvider {
    static var previews: some View {
        LessonsPage()
    }
}

