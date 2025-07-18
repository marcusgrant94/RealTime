//
//  CameraPreview.swift
//  RealTime
//
//  Created by Marcus Grant on 11/21/23.
//

import SwiftUI
import AVFoundation
import UIKit
import Firebase
import FirebaseStorage
import FirebaseCore

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    @Published var isSessionRunning = false
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let movieFileOutput = AVCaptureMovieFileOutput()
    @Published var capturedImage: UIImage?
    @Published var capturedVideoURL: URL?
    @Published var showSaveAlert = false
    @Published var showUploadButton = false
    @Published var selectedFriendIds = Set<String>()
    @Published var showToast = false
    var onPhotoSent: (() -> Void)?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    
    override init() {
        super.init()
        setupSession()
    }
    
    func uploadPhotoToStories(
        userID: String,
        completion: @escaping () -> Void
      ) {
        guard let image = capturedImage,
              let data  = image.jpegData(compressionQuality: 0.8)
        else {
          completion()
          return
        }

        let id = UUID().uuidString
        let ref = Storage.storage().reference().child("stories/\(id).jpg")
        ref.putData(data, metadata: nil) { _,err in
          if let e = err {
            print("❌ upload error:", e)
            completion(); return
          }
          ref.downloadURL { url,_ in
            guard let url = url else { completion(); return }
            let story: [String:Any] = [
              "id":        id,
              "userId":    userID,
              "imageUrl":  url.absoluteString,
              "timestamp": Timestamp()
            ]
            Firestore.firestore()
              .collection("stories")
              .document(id)
              .setData(story) { err in
                if let e = err { print("❌ write error:", e) }
                self.capturedImage  = nil
                self.showUploadButton = false
                self.showToast     = true
                // fire your onPhotoSent (hides overlay)
                DispatchQueue.main.async {
                  self.onPhotoSent?()
                  completion()
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                  self.showToast = false
                }
              }
          }
        }
      }
    
    func selectFriend(id: String) {
        if selectedFriendIds.contains(id) {
            selectedFriendIds.remove(id)
        } else {
            selectedFriendIds.insert(id)
        }
    }
    
    func sendPhotoToSelectedFriends(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Could not convert image to Data")
            return
        }

        let imageID = UUID().uuidString
        let storageRef = Storage.storage().reference().child("message_images/\(imageID).jpg")

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading photo: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Download URL not found")
                    return
                }

                // 🔥 Fetch sender's name from Firestore instead of UserDefaults
                let currentUserID = Auth.auth().currentUser?.uid ?? ""
                let db = Firestore.firestore()
                db.collection("users").document(currentUserID).getDocument { (docSnap, error) in
                    guard let doc = docSnap, let data = doc.data(), let currentUserName = data["name"] as? String else {
                        print("Could not fetch current user's name, using 'Unknown'")
                        return
                    }

                    for friendID in self.selectedFriendIds {
                        let messageData: [String: Any] = [
                            "senderId": currentUserID,
                            "senderName": currentUserName, // ✅ always accurate now
                            "recipientId": friendID,
                            "timestamp": Timestamp(date: Date()),
                            "imageURL": downloadURL.absoluteString,
                            "text": "" // Empty text for image message
                        ]

                        db.collection("messages").addDocument(data: messageData) { error in
                            if let error = error {
                                print("Error sending message: \(error.localizedDescription)")
                            } else {
                                print("Image message successfully sent")
                                
                                DispatchQueue.main.async {
                                    self.showToast = true
                                    self.onPhotoSent?()
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.showToast = false
                            }
                        }
                    }
                }
            }
        }
    }

    
    
    
    
    
    func switchCamera() {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }

        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)

        let newPosition = currentInput.device.position == .back ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        guard let newCameraDevice = getCamera(newPosition) else {
            print("Could not get new camera device")
            captureSession.commitConfiguration()
            return
        }

        guard let newVideoInput = try? AVCaptureDeviceInput(device: newCameraDevice), captureSession.canAddInput(newVideoInput) else {
            print("Could not create video input")
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(newVideoInput)
        captureSession.commitConfiguration()
    }


    private func getCamera(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        #if targetEnvironment(simulator)
        // Running on the simulator - return nil or dummy device
        print("Camera not available on simulator")
        return nil
        #else
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices
        return devices.first
        #endif
    }


    

    func setupSession(withPosition position: AVCaptureDevice.Position = .back) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let videoCaptureDevice = self.getCamera(position),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  self.captureSession.canAddInput(videoInput),
                  self.captureSession.canAddOutput(self.photoOutput),
                  self.captureSession.canAddOutput(self.movieFileOutput) else {
                return
            }

            self.captureSession.beginConfiguration()
            self.captureSession.addInput(videoInput)
            self.captureSession.addOutput(self.photoOutput)
            self.captureSession.addOutput(self.movieFileOutput)
            self.captureSession.commitConfiguration()

            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }


    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func startRecording() {
        if movieFileOutput.isRecording == false {
            if let connection = movieFileOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }

            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }

    func stopRecording() {
        if movieFileOutput.isRecording == true {
            movieFileOutput.stopRecording()
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
            print("Captured image: \(image)")
            self.showUploadButton = true  // Indicate that the photo is ready for upload
        }
    }

    
    func saveImageToLibrary(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func stopAndResetSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
        for input in captureSession.inputs  { captureSession.removeInput(input)  }
        for output in captureSession.outputs { captureSession.removeOutput(output) }
      }

    func restartSession() {
        print("📸 restarting session…")
        setupSession()      // your existing method that adds inputs/outputs
        captureSession.startRunning()
        DispatchQueue.main.async {
          self.isSessionRunning = true
          // if you stored your previewLayer, reconnect it:
          self.previewLayer?.session = self.captureSession
        }
      }
    

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving photo: \(error.localizedDescription)")
        } else {
            self.showSaveAlert = true
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
           if let error = error {
               print("Error recording video: \(error.localizedDescription)")
           } else {
               // Store the URL of the captured video
               DispatchQueue.main.async {
                   self.capturedVideoURL = outputFileURL
               }
           }
       }
   }


struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var viewModel: CameraViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
            let view = UIView(frame: UIScreen.main.bounds)
            // ← Make this match your brand/dark theme:
            view.backgroundColor = UIColor(red: 22/255, green: 29/255, blue: 35/255, alpha: 1)

            let previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            return view
        }

    private func setupCamera(view: UIView, context: Context) {
        viewModel.setupSession()
        let previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
            viewModel.previewLayer?.frame = uiView.bounds
        }
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
        var parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            // Implementation same as in CameraViewModel
        }
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            // Implementation same as in CameraViewModel
        }
    }
}
