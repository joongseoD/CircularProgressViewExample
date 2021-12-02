import UIKit
import PlaygroundSupport

public final class CircularProgressView: UIView {
    private let startPoint = CGFloat(-Double.pi / 2)
    private let endPoint = CGFloat(3 * Double.pi / 2)
    
    private lazy var stopView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = progressColor
        return view
    }()
    
    private lazy var progressView: UIView = {
        let progressView = UIView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        progressView.layer.addSublayer(trackLayer)
        progressView.layer.addSublayer(progressLayer)
        return progressView
    }()
    
    private lazy var trackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        setup(shapeLayer: layer)
        layer.strokeColor = trackColor.cgColor
        layer.strokeEnd = 1.0
        return layer
    }()
    
    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        setup(shapeLayer: layer)
        layer.strokeColor = progressColor.cgColor
        layer.strokeEnd = 0.0
        return layer
    }()
    
    private func setup(shapeLayer: CAShapeLayer) {
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 10.0
    }
    
    private var progress: CGFloat = 0
    
    //MARK: - Pulbic Properties
    public var trackColor: UIColor = .lightGray {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    public var progressColor: UIColor = .black {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
            stopView.backgroundColor = progressColor
        }
    }
    
    public var lineWidth: CGFloat = 10 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
        }
    }
    
    public var stopCornerRadius: CGFloat = 0 {
        didSet {
            stopView.layer.cornerRadius = stopCornerRadius
        }
    }
    
    public var onStop: (() -> Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
        setupTapGesture()
    }
    
    private func setupLayout() {
        addSubview(progressView)
        progressView.addSubview(stopView)
        
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stopView.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
            stopView.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            stopView.widthAnchor.constraint(equalTo: progressView.widthAnchor, multiplier: 0.5),
            stopView.heightAnchor.constraint(equalTo: progressView.heightAnchor, multiplier: 0.5),
        ])
    }
    
    private func setupTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(progressDidTap))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func progressDidTap() {
        onStop?()
        progressLayer.strokeEnd = progress
        progressLayer.removeAllAnimations()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        setupProgressView()
    }
    
    private func setupProgressView() {
        let circularPath = UIBezierPath(arcCenter: progressView.center,
                                        radius: progressView.bounds.width / 2,
                                        startAngle: startPoint,
                                        endAngle: endPoint,
                                        clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }
}

//MARK: - Public Functions
public extension CircularProgressView {
    ///During the duration, the progression is animated.
    func animate(duration: TimeInterval) {
        set(progress: 1.0, duration: duration)
    }
    
    ///During the duration, the progression is animated as much as the progress value.
    func set(progress: CGFloat, duration: TimeInterval) {
        self.progress = progress
        
        let circularProgressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        circularProgressAnimation.duration = duration
        circularProgressAnimation.toValue = progress
        circularProgressAnimation.fillMode = .forwards
        circularProgressAnimation.isRemovedOnCompletion = false
        progressLayer.add(circularProgressAnimation, forKey: nil)
    }
    
    func set(progress: CGFloat) {
        self.progress = progress
        progressLayer.strokeEnd = progress
    }
}


final class ViewController: UIViewController {
    
    private let startButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.circle.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 150, weight: .bold)),
                        for: .normal)
        button.tintColor = .systemPink
        button.addTarget(self, action: #selector(startDownload), for: .touchUpInside)
        return button
    }()
    
    private let progressView: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.trackColor = .lightGray
        view.progressColor = .systemPink
        view.stopCornerRadius = 17
        view.isHidden = true
        return view
    }()
    
    private var downloading: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    private func setupView() {
        view.addSubview(startButton)
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 150),
            startButton.heightAnchor.constraint(equalToConstant: 150),
            
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 150),
            progressView.heightAnchor.constraint(equalToConstant: 150),
        ])
    }
    
    @objc private func startDownload() {
        startButton.isHidden = true
        progressView.isHidden = false
        
        downloadData()
    }
    
    private func stopDownload() {
        downloading = false
        startButton.isHidden = false
        progressView.isHidden = true
        progressView.set(progress: 0)
    }
    
    private func downloadData() {
        downloading = true
        
        progressView.onStop = { [weak self] in
            self?.stopDownload()
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            [0.1, 0.3, 0.7, 1.0].forEach { progress in
                guard self.downloading else { return }
                DispatchQueue.main.async {
                    self.progressView.set(progress: progress, duration: 0.5)
                }
                Thread.sleep(forTimeInterval: 1)
            }
        }
        
        //or, set animating duration
//        progressView.animate(duration: 3)
    }
}


var viewController: ViewController? = ViewController()
PlaygroundPage.current.liveView = viewController
PlaygroundPage.current.needsIndefiniteExecution = true
