"""Distance-field inset for a single star-shaped neck contour; no dependencies.
Keeps cyclic correspondence while removing angular backtracking in inner rings.
Fails explicitly if the contour cannot support the requested inset.
"""
import math

def distance(point, ring):
    best=float('inf')
    for i,a in enumerate(ring):
        b=ring[(i+1)%len(ring)];dx=b[0]-a[0];dy=b[1]-a[1]
        t=max(0.0,min(1.0,((point[0]-a[0])*dx+(point[1]-a[1])*dy)/max(dx*dx+dy*dy,1e-30)))
        best=min(best,math.hypot(point[0]-a[0]-dx*t,point[1]-a[1]-dy*t))
    return best

def inset(ring, thickness):
    assert distance((0,0),ring)>thickness, 'Inset consumes the neck center'
    angles=[]
    for p in ring:
        angle=math.atan2(p[1],p[0])
        if angles:
            while angle<angles[-1]-math.pi:angle+=math.tau
            while angle>angles[-1]+math.pi:angle-=math.tau
            angle=max(angle,angles[-1]+.001)
        angles.append(angle)
    assert angles[-1]<angles[0]+math.tau-.0001,'Contour is not a single cyclic radial loop'
    limit=max(math.hypot(*p) for p in ring)*1.5
    result=[]
    for angle in angles:
        direction=(math.cos(angle),math.sin(angle));lo=0.0;hi=None
        for step in range(1,513):
            candidate=limit*step/512
            if distance((direction[0]*candidate,direction[1]*candidate),ring)<=thickness:
                hi=candidate;break
            lo=candidate
        assert hi is not None,'Ray missed the inset; contour requires another method'
        for _ in range(32):
            mid=(lo+hi)*.5
            if distance((direction[0]*mid,direction[1]*mid),ring)>thickness:lo=mid
            else:hi=mid
        radius=(lo+hi)*.5
        point=(direction[0]*radius,direction[1]*radius)
        assert abs(distance(point,ring)-thickness)<1e-7
        result.append(point)
    return result
